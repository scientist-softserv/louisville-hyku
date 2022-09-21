# frozen_string_literal: true

module CustomSlugs
  # adds custom slug attributes to solr document
  # @see app/models/custom_slugs/slug_README.md

  module SlugSolrAttributes
    extend ActiveSupport::Concern
    included do
      attribute :fedora_id, Hyrax::SolrDocument::Metadata::Solr::String, 'fedora_id_ssi'
      attribute :slug, Hyrax::SolrDocument::Metadata::Solr::String, 'slug_tesim'

      def to_param
        slug || id
      end
    end
  end
end
