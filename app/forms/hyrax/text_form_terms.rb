# frozen_string_literal: true

module Hyrax
  module TextFormTerms
    include Hyrax::Forms
    # overrides Hyrax::Forms::WorkForm
    # to display 'license' in the 'base-terms' div on the user dashboard "Add New Work" description
    # by getting iterated over in hyrax/app/views/hyrax/base/_form_metadata.html.erb
    def primary_terms
      super + %i[
        alternative_title
        volume
        issue
        creator
        creator_role
        contributor
        contributor_role
        description
        table_of_contents
        location
        subject
        mesh
        keyword
        people_represented
        date_created
        language
        resource_type
        source
        collection_information
        publisher
        rights_statement
        ordering_information
        related_url
        resource_query
        searchable_text
      ]
    end
  end
end
