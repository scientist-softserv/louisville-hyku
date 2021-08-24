module Hyrax
  module ArtFormTerms
    include Hyrax::Forms
    # overrides Hyrax::Forms::WorkForm
    # to display 'license' in the 'base-terms' div on the user dashboard "Add New Work" description
    # by getting iterated over in hyrax/app/views/hyrax/base/_form_metadata.html.erb
    def primary_terms
      super + %i[
                    alternative_title
                    creator
                    creator_role
                    contributor
                    contributor_role
                    description
                    keyword
                    subject
                    people_represented
                    location
                    date_created
                    decade
                    resource_type
                    source
                    collection_information
                    publisher
                    format 
                    rights_statement 
                    ordering_information
                    language
                    resource_query
                    biography_of_contributor
                    cataloguing_note
                    condition
                    contributor_description
                    contributor_history
                    cultural_context
                    data_source
                    description_1990
                    descriptor
                    exhibit_history
                    honoree
                    inscription
                    iqb
                    language_script
                    location_of_contributor
                    location_of_honoree
                    material
                    measurement
                    object_location
                    ornamentation
                    place_original
                    related_material_and_publication_history
                    related_url
                    resource_repository
                    style
                    technique
                    theme
                    transcription_translation
                    translated_title
                    type_of_honoree
                    type_of_work
                ]
    end
  end
end
