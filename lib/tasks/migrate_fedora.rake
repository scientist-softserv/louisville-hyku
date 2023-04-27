# frozen_string_literal: true

namespace :louisville do
  desc 'Migrate metadata from a simple file Fedora db to a postgres-backed Fedora db without reprocessing files'
  task migrate_fedora: [:environment] do
    AccountElevator.switch!(Account.first.cname)

    Hyrax::CollectionType.find_or_create_default_collection_type
    Hyrax::CollectionType.find_or_create_admin_set_type

    # TODO: Smartly create non-default AdminSets
    #       Possibly call from Solr and recreate all that way
    begin
      AdminSet.find_or_create_default_admin_set_id
    rescue ActiveRecord::RecordNotUnique => e
      # TODO: make pretty
      puts "Suppressing #{e.class} error since it is expected."
      puts "The PermissionTemplate for the default AdminSet already exists, but tries to recreate itself and complains. At this point, however, the default AdminSet has been created successfully, which is what we care about."
    end

    errors = {}
    importer_ids = Bulkrax::Importer.pluck(:id)
    collection_ids = []
    importer_ids.each do |importer_id|
      importer = Bulkrax::Importer.find(importer_id)
      importer.entries.find_each do |entry|
        begin
          if entry.class.to_s.include?('Collection')
            collection_ids << entry.id
            next
          end
          puts "Importing #{entry.class} #{entry.id}"
          slug = entry.identifier.truncate(75, omission: '').parameterize.underscore
          file_set_ids = SolrDocument.find(slug).file_set_ids
          entry.raw_metadata['file_set_ids'] = file_set_ids
          entry.save
          entry.build
        rescue => e
          errors[entry.id] = e.message
        end
      end
    end

    collection_ids.each do |collection_id|
      begin
        entry = Bulkrax::Entry.find(collection_id)
        puts "Importing #{entry.class} #{entry.id}"
        fedora_id = SolrDocument.find(entry.identifier.truncate(75, omission: '').parameterize.underscore).fedora_id
        entry.raw_metadata['id'] = fedora_id
        entry.save
        entry.build
      rescue => e
        errors[entry.id] = e.message
      end
    end

    importer_ids.each_with_index do |importer_id, i|
      Bulkrax::ScheduleRelationshipsJob.set(wait: i.minutes).perform_later(importer_id: importer_id)
    end




    # keeping old IDs for collections and file sets, but allowing new ones to be generated
    # for works (both parents and children)

    # TODO: non-collection entry building (batch by importer?)
    # TODO: stop new derivative creation (create FileSets with old IDs?)
    #       Add work id and fileset id to work's raw_metadata
    #       Override factory to use fileset id if present

    # loop through all CsvCollectionEntries (by importer?)
    # grab all data for each from solr
    # add data to new Collection instance, including ID
    # save collection

    # TODO: rerun bulkrax relationships

    error_log = File.open(File.join(Rails.root, 'tmp', 'fedora_migrate_errors.log'), 'w')
    error_log.puts errors.inspect
    error_log.close

    puts "errors were detected, check log file: tmp/fedora_migrate_errors.log" if errors.any?
  end
end
