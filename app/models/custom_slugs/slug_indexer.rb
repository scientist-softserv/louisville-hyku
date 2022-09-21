# frozen_string_literal: true

module CustomSlugs
  # indexes necessary fields into solr document
  # The fedora id is indexed into solr as fedora_id_ssi.
  # The solr id becomes the slug if there is one, otherwise it remains the same as the fedora id.
  # @see app/models/custom_slugs/slug_README.md

  module SlugIndexer
    def generate_solr_document
      super.tap do |solr_doc|
        solr_doc['fedora_id_ssi'] = object.id # stores fedora id
        solr_doc[ActiveFedora.id_field.to_sym] = object.to_param # overrides solr id with slug value
      end
    end
  end
end
