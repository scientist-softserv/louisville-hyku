# frozen_string_literal: true

Bulkrax.setup do |config|
  # Add local parsers
  # config.parsers += [
  #   { name: 'MODS - My Local MODS parser', class_name: 'Bulkrax::ModsXmlParser', partial: 'mods_fields' },
  # ]

  # Field to use during import to identify if the Work or Collection already exists.
  # Default is 'source'.
  config.system_identifier_field = 'identifier'

  # WorkType to use as the default if none is specified in the import
  # Default is the first returned by Hyrax.config.curation_concerns
  config.default_work_type = 'Image'

  # Path to store pending imports
  config.import_path = 'tmp/imports'

  # Path to store exports before download
  config.export_path = 'tmp/exports'

  # Server name for oai request header
  # config.server_name = 'my_server@name.com'

  config.field_mappings = {
    "Bulkrax::CsvParser" => {
      "alternative_title" => { from: ["alternative_title"], split: ";" },
      "identifier" => { from: ["identifier"], split: ";" },
      "title" => { from: ["title"], split: ";" },
      "contributor" => { from: ["contributor"], split: ";" },
      "contributor_role" => { from: ["contributor_role"], split: ";" },
      "publisher" => { from: ["repository"], split: ";" },
      "people_represented" => { from: ["people_represented"], split: ";" },
      "creator" => { from: ["creator"], split: ";" },
      "creator_role" => { from: ["creator_role"], split: ";" },
      "date_created" => { from: ["date_original"] },
      "decade" => { from: ["decade"], split: ";" },
      "description" => { from: ["description"] },
      "resource_type" => { from: ["object_type"], split: ";" },
      "collection_information" => { from: ["collection_information"], split: ";" },
      "artificial_collection" => { from: ["artificial_collection"], split: ";" },
      "digitization_specification" => { from: ["digitization_specification"] },
      "date_digital" => { from: ["date_digital"] },
      "media_type" => { from: ["media_type"], split: ";" },
      "format" => { from: ["format"], split: ";" },
      "ordering_information" => { from: ["ordering_information"] },
      "administrative_note" => { from: ["administrative_note"] },
      "resource_query" => { from: ["resource_query"], split: ";" },
      "resource_date_created" => { from: ["resource_date_created"] },
      "source" => { from: ["source"], split: ";" },
      "building_date" => { from: ["building_date"], split: ";" },
      "code" => { from: ["code"], split: ";" },
      "extent" => { from: ["duration"] },
      "invoice_information" => { from: ["invoice_information"] },
      "language" => { from: ["language"], split: ";" },
      "operating_area" => { from: ["operating_area"], split: ";" },
      "photo_comment" => { from: ["photo_comment"] },
      "production" => { from: ["production"] },
      "region" => { from: ["region"] },
      "related_image" => { from: ["related_image"], split: ";" },
      "related_url" => { from: ["related_resource"], split: ";" },
      "series" => { from: ["series"] },
      "story" => { from: ["story"] },
      "subject" => { from: ["subject"], split: ";" },
      "mesh" => { from: ["mesh"], split: ";" },
      "tab_heading" => { from: ["tab_heading"] },
      "people_named" => { from: ["people_named"], split: ";" },
      "location" => { from: ["location"], split: ";" },
      "table_of_contents" => { from: ["table_of_contents"] },
      "volume" => { from: ["volume"] },
      "issue" => { from: ["issue"] },
      "searchable_text" => { from: ["searchable_text"] },
      "biography_of_contributor" => { from: ["biography_of_contributor"] },
      "cataloguing_note" => { from: ["cataloguing_note"] },
      "condition" => { from: ["condition"], split: ";" },
      "contributor_description" => { from: ["contributor_description"] },
      "contributor_history" => { from: ["contributor_history"] },
      "cultural_context" => { from: ["cultural_context"], split: ";" },
      "data_source" => { from: ["data_source"] },
      "description_1990" => { from: ["description_1990"] },
      "descriptor" => { from: ["descriptor"], split: ";" },
      "exhibit_history" => { from: ["exhibit_history"] },
      "honoree" => { from: ["honoree"], split: ";" },
      "inscription" => { from: ["inscription"] },
      "iqb" => { from: ["iqb"] },
      "language_script" => { from: ["language_script"], split: ";" },
      "location_of_contributor" => { from: ["location_of_contributor"], split: ";" },
      "location_of_honoree" => { from: ["location_of_honoree"], split: ";" },
      "material" => { from: ["material"], split: ";" },
      "measurement" => { from: ["measurement"] },
      "object_location" => { from: ["object_location"] },
      "ornamentation" => { from: ["ornamentation"], split: ";" },
      "place_original" => { from: ["place_original"], split: ";" },
      "related_material_and_publication_history" => { from: ["related_material_and_publication_history"] },
      "resource_repository" => { from: ["resource_repository"] },
      "style" => { from: ["style"], split: ";" },
      "technique" => { from: ["technique"], split: ";" },
      "theme" => { from: ["theme"], split: ";" },
      "transcription_translation" => { from: ["transcription_translation"] },
      "translated_title" => { from: ["translated_title"] },
      "type_of_honoree" => { from: ["type_of_honoree"] },
      "type_of_work" => { from: ["type_of_work"] },
      "children" => { from: ["children"], split: ";" },
    }
  } 

  # Field_mapping for establishing a parent-child relationship (FROM parent TO child)
  # This can be a Collection to Work, or Work to Work relationship
  # This value IS NOT used for OAI, so setting the OAI Entries here will have no effect
  # The mapping is supplied per Entry, provide the full class name as a string, eg. 'Bulkrax::CsvEntry'
  # Example:
  #   {
  #     'Bulkrax::RdfEntry'  => 'http://opaquenamespace.org/ns/contents',
  #     'Bulkrax::CsvEntry'  => 'children'
  #   }
  # By default no parent-child relationships are added
  config.parent_child_field_mapping = {
    'Bulkrax::CsvEntry' => 'children'
  } 

  # Field_mapping for establishing a collection relationship (FROM work TO collection)
  # This value IS NOT used for OAI, so setting the OAI parser here will have no effect
  # The mapping is supplied per Entry, provide the full class name as a string, eg. 'Bulkrax::CsvEntry'
  # The default value for CSV is collection
  # Add/replace parsers, for example:
  # config.collection_field_mapping['Bulkrax::RdfEntry'] = 'http://opaquenamespace.org/ns/set'

  # Field mappings
  # Create a completely new set of mappings by replacing the whole set as follows
  #   config.field_mappings = {
  #     "Bulkrax::OaiDcParser" => { **individual field mappings go here*** }
  #   }

  # Add to, or change existing mappings as follows
  #   e.g. to exclude date
  #   config.field_mappings["Bulkrax::OaiDcParser"]["date"] = { from: ["date"], excluded: true  }

  # To duplicate a set of mappings from one parser to another
  #   config.field_mappings["Bulkrax::OaiOmekaParser"] = {}
  #   config.field_mappings["Bulkrax::OaiDcParser"].each {|key,value| config.field_mappings["Bulkrax::OaiOmekaParser"][key] = value }

  # Properties that should not be used in imports/exports. They are reserved for use by Hyrax.
  # config.reserved_properties += ['my_field']
end
