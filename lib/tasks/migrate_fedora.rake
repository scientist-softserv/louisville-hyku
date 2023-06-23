# frozen_string_literal: true

namespace :louisville do
  desc 'Migrate metadata from a simple file Fedora db to a postgres-backed Fedora db without reprocessing files'
  task migrate_fedora: [:environment] do
    # ************************************************************************
    # FEDORA RECORDS NOT ASSOCIATED WITH A BULKRAX ENTRY WILL NOT BE RESTORED!
    #
    # This rake task will only restore Fedora data that was ingested using Bulkrax.
    # Making a database backup before running this task is strongly recommended.
    # ************************************************************************
    #
    # This rake task is for migrating from a simple file Fedora database to a postgres-backed
    # Fedora database. It is designed to process Fedora metadata only; no file binary or
    # derivative processing will occur, saving time and system resources. Instead, it will
    # link up the newly created Fedora records with the existing binary and derivative data.
    #
    # The system-generated Fedora IDs for Collections and FileSets will be restored, but
    # works will be restored with new IDs.
    # Reasoning:
    # - Collections: This is important for data parity (pre-migration vs. post-migration).
    #                Hyrax::PermissionTemplate and other records associated with Collections
    #                use the Collection's Fedora ID to link together. Allowing a restored
    #                Collection to generate a new system ID would mean a new Hyrax::PermissionTemplate
    #                would be created, leading to two things we don't want:
    #                  - "Orphaned" records associated with the old Collection ID
    #                  - Loss of pre-migrated Collection permissions customizations
    # - FileSets: This is what allows us to skip derivative reprocessing. The file path for
    #             derivatives is the FileSet's ID, so if a FileSet is created with the same
    #             ID, it will find the existing derivatives at that location and use those.
    #             This depends on an override:
    #             @see app/jobs/create_derivatives_job.rb
    # - Works: Attempting to restoring a work's original Fedora ID leads to a couple different
    #          errors. Parent works (i.e. works with child works) will throw PG::UniqueViolation
    #          when trying to create the work's Sipity::Entity. The other error is related to
    #          how work-to-work relationships get indexed in LV Hyku; when being indexed, a work
    #          tries to look at both its parent and child relationships. Since these still exist
    #          in Solr, but not yet Fedora, a ActiveFedora::ObjectNotFoundError error is thrown.
    #          @see AppIndexer#descendent_member_ids_for
    #          @see AppIndexer#ancestor_ids
    #          A side effect of restoring works with new IDs is that associated records not
    #          accounted for in the Bulkrax Entry will be disconnected. This includes, but
    #          is not limited to, relationships manually added through the UI.

    logger = Logger.new(Rails.root.join('tmp', 'migrate_fedora.log'))

    # NOTE: Only works for single tenant Hyku apps
    AccountElevator.switch!(Account.first.cname)

    logger.info 'START creating CollectionTypes and default AdminSet'
    Hyrax::CollectionType.find_or_create_default_collection_type
    Hyrax::CollectionType.find_or_create_admin_set_type

    # NOTE: If you have more than just the Default Admin Set, you'll need to figure out
    #       how to restore the rest of them as well.
    begin
      AdminSet.find_or_create_default_admin_set_id
    rescue ActiveRecord::RecordNotUnique => e
      logger.debug('************************************************************')
      logger.debug("Suppressing #{e.class} error since it is expected.")
      logger.debug('The PermissionTemplate for the default AdminSet already exists,')
      logger.debug('but tries to recreate itself and complains.')
      logger.debug('At this point, however, the default AdminSet has been created successfully,')
      logger.debug('which is what we care about.')
      logger.debug('************************************************************')
    end

    errors = {}
    importer_ids = Bulkrax::Importer.pluck(:id)
    collection_entry_ids = []

    # Use importers to naturally batch records. A benefit to this method is that it
    # all but guarantees all required records will exist when we process relationships.
    importer_ids.each do |importer_id|
      importer = Bulkrax::Importer.find(importer_id)
      logger.info "START migrating work entries for Importer ID #{importer_id}"
      importer.entries.find_each do |entry|
        begin
          # Attempting to restore a Collection when some, but not all, works have been restored
          # will throw an Ldp::BadRequest error. This is because it attempts to query its
          # member works and finds only some of them. We opt to restore all Collections after
          # all works have been restored to avoid this.
          if entry.class.to_s.include?('Collection')
            collection_entry_ids << entry.id
            next
          end
          logger.info "Importing #{entry.class} #{entry.id}"
          # In LV Hyku, a record's slug is its ID. To look up the record most efficiently using #find,
          # we parse the slug the same way the app does it.
          # @see CustomSlugs::SlugBehavior#set_slug
          slug = entry.identifier.truncate(75, omission: '').parameterize.underscore
          # SolrDocument#file_set_ids includes child work IDs. This will break if :file_set_ids_ssim
          # is indexed in a different order since AttachFilesToWorkJob#perform calls #shift on them.
          # @see AttachFilesToWorkJob#perform
          # @see AppIndexer#descendent_member_ids_for
          file_set_ids_to_restore = SolrDocument.find(slug).file_set_ids
          # file_set_ids_to_restore is a transient attribute; it does not directly map
          # to any metadata property. It is custom to this task.
          # Passing an Array of IDs to the Entry's raw_metadata will lead to
          # that record's FileSet children being restored with the provided IDs.
          entry.raw_metadata['file_set_ids_to_restore'] = file_set_ids_to_restore
          entry.save
          entry.build
        rescue => e # rubocop:disable Style/RescueStandardError
          errors[entry.id] = "#{e.class} - #{e.message}"
          logger.warn 'ERROR logged, continuing...'
        end
      end
    end

    logger.info 'START migrating all Collection entries'
    collection_entry_ids.each do |col_entry_id|
      begin
        entry = Bulkrax::Entry.find(col_entry_id)
        logger.info "Importing #{entry.class} #{entry.id}"
        # In LV Hyku, a record's slug is its ID. To look up the record most efficiently using #find,
        # we parse the slug the same way the app does it.
        # @see CustomSlugs::SlugBehavior#set_slug
        slug = entry.identifier.truncate(75, omission: '').parameterize.underscore
        # In LV Hyku, a record's system-generated ID is persisted in a field called :fedora_id
        fedora_id = SolrDocument.find(slug).fedora_id
        # Passing a record's ID through the Entry's raw_metadata will lead to that record being
        # restored with the provided ID.
        entry.raw_metadata['id'] = fedora_id
        entry.save
        entry.build
      rescue => e # rubocop:disable Style/RescueStandardError
        errors[entry.id] = "#{e.class} - #{e.message}"
        logger.warn 'ERROR logged, continuing...'
      end
    end

    logger.info 'START scheduling relationship jobs for all Importers'
    importer_ids.each_with_index do |importer_id, i|
      Bulkrax::ScheduleRelationshipsJob.set(wait: i.minutes).perform_later(importer_id: importer_id)
    end

    if errors.any?
      error_log = File.open(Rails.root.join('tmp', 'migrate_fedora_errors.json'), 'w')
      error_log.puts errors.to_json
      error_log.close

      logger.error '************************************************************'
      logger.error 'Errors were detected, check log file: tmp/migrate_fedora_errors.log'
      logger.error '************************************************************'
    end
    logger.info 'DONE migrating Fedora'
  end

  desc 'Run Bulkrax Relationships'
  task run_relationships: [:environment] do
    # ************************************************************************
    # This is an optional step that will connect the relationships early if needed. This
    # step will be run in the above migrate_fedora job, so there is no need to run this
    # step unless you need the relationships quicker.
    # ************************************************************************
    AccountElevator.switch!(Account.first.cname)
    importer_ids = Bulkrax::Importer.pluck(:id)
    importer_ids.each do |importer_id|
      importer = Bulkrax::Importer.find(importer_id)
      importer.last_run.parents.each do |parent_id|
        Bulkrax::CreateRelationshipsJob.perform_later(parent_identifier: parent_id, importer_run_id: importer.last_run.id)
      end
    end
  end

  desc "Update Migration"
  task update_migration: [:environment] do
    logger = Logger.new(Rails.root.join('tmp', 'migration_update.log'))
    errors = {}
    # NOTE: Only works for single tenant Hyku apps
    AccountElevator.switch!(Account.first.cname)


    collection_entry_ids = []
    sql_query = <<-SQL
      SELECT id FROM bulkrax_entries
      WHERE id IN (
        SELECT MAX(id) FROM bulkrax_entries
        GROUP BY identifier
      );
    SQL
    Bulkrax::Entry.find_by_sql(sql_query).pluck(:id).sort.each do |entry_id|
      recent_entry = Bulkrax::Entry.find(entry_id)
      if recent_entry.is_a?(Bulkrax::CsvCollectionEntry)
        collection_entry_ids << recent_entry.id
      else
        sorted_entries = Bulkrax::Entry.where(identifier: recent_entry.identifier).sort_by(&:id)


        files = sorted_entries.map do |e|
          e.raw_metadata["file"] if e.raw_metadata["file"].present?
        end.flatten.compact.uniq

        files.each do |file|
          solr_docs = ActiveFedora::SolrService.query("title_tesim:#{file}")
          solr_doc = solr_docs.select { |doc| doc['title_tesim'].first == file }.first
          if solr_doc.blank?
            logger.warn "no matching solr_doc found with the title #{file}"
            next
          end
          unless recent_entry.parsed_metadata['file_set_ids_to_restore'].include?(solr_doc.id)
            logger.warn "file_set #{solr_doc.id} found that was not part of the import for entry #{recent_entry.identifier}"
          end
        end

        parents = sorted_entries.map do |e|
          e.parsed_metadata["parents"].presence
        end.flatten.compact.uniq

        children = sorted_entries.map do |e|
          e.parsed_metadata["children"].presence
        end.flatten.compact.uniq

        recent_entry.parsed_metadata.merge!({"parents" => parents}) if parents.present?
        recent_entry.parsed_metadata.merge!({"children" => parents}) if children.present?

        recent_entry.save
        recent_entry.build

        work = nil
        parents.each do |parent_id|
          parent = ActiveFedora::Base.find(parent_id.truncate(75, omission: '').parameterize.underscore)
          next unless parent.class.name.include?("Collection") # need to address

          work ||= ActiveFedora::Base.find(recent_entry.identifier.truncate(75, omission: '').parameterize.underscore)
          work.member_of_collections << parent
        end

        if children.present?
          records_hash = {}
          user = User.first
          children.map! do |child_id|
            r = ActiveFedora::Base.find(child_id.truncate(75, omission: '').parameterize.underscore)
            r.class.name.include?("Collection") ? nil : r # address this or nah?
          end.compact!
          children.each_with_index do |child_record, i|
            records_hash[i] = { id: child_record.id }
          end
          attrs = { work_members_attributes: records_hash }
          work ||= ActiveFedora::Base.find(recent_entry.identifier.truncate(75, omission: '').parameterize.underscore)
          env = Hyrax::Actors::Environment.new(work, Ability.new(user), attrs)

          Hyrax::CurationConcern.actor.update(env)
        end

        work.save! if work.present?
      end
    rescue => e # rubocop:disable Style/RescueStandardError
      errors[recent_entry.id] = "#{e.class} - #{e.message}"
      logger.warn 'ERROR logged, continuing...'
    end
    ensure
      if errors.any?
        error_log = File.open(Rails.root.join('tmp', 'migration_update_errors.json'), 'w')
        error_log.puts errors.to_json
        error_log.close

        logger.error '************************************************************'
        logger.error 'Errors were detected, check log file: tmp/migration_update_errors.log'
        logger.error '************************************************************'
      end
  end
end
