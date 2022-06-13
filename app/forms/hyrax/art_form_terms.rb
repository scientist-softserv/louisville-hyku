# frozen_string_literal: true

module Hyrax
  module ArtFormTerms
    include Hyrax::Forms
    # overrides Hyrax::Forms::WorkForm
    # to display 'license' in the 'base-terms' div on the user dashboard "Add New Work" description
    # by getting iterated over in hyrax/app/views/hyrax/base/_form_metadata.html.erb
    def primary_terms
      super + %i[
        alternative_title
        honoree
        type_of_honoree
        location_of_honoree
        creator
        creator_role
        contributor
        contributor_role
        location_of_contributor
        biography_of_contributor
        contributor_history
        contributor_description
        description
        transcription_translation
        subject
        style
        technique
        material
        ornamentation
        measurement
        cultural_context
        keyword
        language
        language_script
        people_represented
        place_original
        date_created
        resource_type
        exhibit_history
        data_source
        cataloguing_note
        object_location
        condition
        source
        related_image
        collection_information
        publisher
        rights_statement
        ordering_information
        license
        related_url
        resource_query
      ]
    end
  end
end
