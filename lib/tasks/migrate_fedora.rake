# frozen_string_literal: true

namespace :louisville do
  desc 'Migrate metadata from a simple file Fedora db to a postgres-backed Fedora db without reprocessing files'
  task migrate_fedora: [:environment] do
    logger = Logger.new(Rails.root.join('tmp', 'migrate_fedora.log'))

    # NOTE: Only works for single tenant Hyku apps
    AccountElevator.switch!(Account.first.cname)

    Hyrax::CollectionType.find_or_create_default_collection_type
    Hyrax::CollectionType.find_or_create_admin_set_type

    # TODO: Smartly create non-default AdminSets
    #       Possibly call from Solr and recreate all that way
    begin
      AdminSet.find_or_create_default_admin_set_id
    rescue ActiveRecord::RecordNotUnique => e
      logger.debug("************************************************************")
      logger.debug("Suppressing #{e.class} error since it is expected.")
      logger.debug("The PermissionTemplate for the default AdminSet already exists,")
      logger.debug("but tries to recreate itself and complains.")
      logger.debug("At this point, however, the default AdminSet has been created successfully,")
      logger.debug("which is what we care about.")
      logger.debug("************************************************************")
    end

    errors = {}
    importer_ids = Bulkrax::Importer.pluck(:id)
    collection_entry_ids = []

    importer_ids.each do |importer_id|
      importer = Bulkrax::Importer.find(importer_id)
      importer.entries.find_each do |entry|
        begin
          if entry.class.to_s.include?('Collection')
            collection_entry_ids << entry.id
            next
          end
          logger.info "Importing #{entry.class} #{entry.id}"
          slug = entry.identifier.truncate(75, omission: '').parameterize.underscore
          # TODO: Includes child works. This will break if :file_set_ids_ssim is indexed
          # in a different order since AttachFilesToWorkJob#perform calls #shift on them
          file_set_ids = SolrDocument.find(slug).file_set_ids
          entry.raw_metadata['file_set_ids'] = file_set_ids
          entry.save
          entry.build
        rescue => e # rubocop:disable Style/RescueStandardError
          errors[entry.id] = e.message
        end
      end
    end

    collection_entry_ids.each do |col_entry_id|
      begin
        entry = Bulkrax::Entry.find(col_entry_id)
        logger.info "Importing #{entry.class} #{entry.id}"
        slug = entry.identifier.truncate(75, omission: '').parameterize.underscore
        fedora_id = SolrDocument.find(slug).fedora_id
        entry.raw_metadata['id'] = fedora_id
        entry.save
        entry.build
      rescue => e # rubocop:disable Style/RescueStandardError
        errors[entry.id] = e.message
      end
    end

    importer_ids.each_with_index do |importer_id, i|
      Bulkrax::ScheduleRelationshipsJob.set(wait: i.minutes).perform_later(importer_id: importer_id)
    end

    if errors.any?
      error_log = File.open(File.join(Rails.root, 'tmp', 'migrate_fedora_errors.log'), 'w')
      error_log.puts errors.inspect
      error_log.close

      logger.error '************************************************************'
      logger.error 'Errors were detected, check log file: tmp/migrate_fedora_errors.log'
      logger.error '************************************************************'
    end
  end
end
