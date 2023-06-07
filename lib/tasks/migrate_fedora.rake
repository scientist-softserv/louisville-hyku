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

  desc 'Get Bulkrax Importer File names'
  task get_importer_file_names: [:environment] do
    # ************************************************************************
    # This task simply returns the names of all the csv files that have been imported.
    # ************************************************************************
    AccountElevator.switch!(Account.first.cname)
    output = File.open(Rails.root.join('tmp', 'importer_file_names.txt'), "w+")
    importer_ids = Bulkrax::Importer.pluck(:id)
    importer_ids.each do |importer_id|
      puts "processing importer: #{importer_id}"
      importer = Bulkrax::Importer.find(importer_id)
      fpath = importer[:parser_fields]['import_file_path'].split('/').last
      output.write("#{importer_id}:#{importer.name}: #{fpath}")
    end
  ensure
    output.close unless output.nil?
  end
end
