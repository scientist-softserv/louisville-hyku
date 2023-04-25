# frozen_string_literal: true

namespace :louisville do
  desc 'Migrate metadata from a simple file Fedora db to a postgres-backed Fedora db without reprocessing files'
  task migrate_fedora: [:environment] do
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
  end
end
