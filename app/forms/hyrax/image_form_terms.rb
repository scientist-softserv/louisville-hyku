# frozen_string_literal: true

module Hyrax
  module ImageFormTerms
    include Hyrax::Forms
    # overrides Hyrax::Forms::WorkForm
    # to display 'license' in the 'base-terms' div on the user dashboard "Add New Work" description
    # by getting iterated over in hyrax/app/views/hyrax/base/_form_metadata.html.erb
    def primary_terms
      super + %i[
        alternative_title
        series
        story
        creator
        creator_role
        contributor
        contributor_role
        description
        invoice_information
        photo_comment
        code
        location
        street
        neighborhood
        city
        county
        region
        operating_area
        subject
        mesh
        tab_heading
        keyword
        production
        people_represented
        date_created
        decade
        building_date
        language
        resource_type
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
