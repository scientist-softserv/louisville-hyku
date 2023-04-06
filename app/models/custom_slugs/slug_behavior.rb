# frozen_string_literal: true

module CustomSlugs
  # Adds custom slug behaviors and properties to works and collection models, built from content of term :identifier
  # @see app/models/custom_slugs/slug_README.md

  module SlugBehavior
    extend ActiveSupport::Concern

    included do
      before_validation :set_slug
      validate :check_slug
      # after_update is necessary when the slug has changed, so solr will have only the new id
      after_update :remove_index_and_reindex
      # adding slug field for custom urls
      property :slug, predicate: CustomSlugs::CustomSlugsTerm.slug, multiple: false do |index|
        index.as :stored_searchable
      end
    end

    def to_param
      slug || id
    end

    def self.find(slug_or_id)
      results = where(slug: slug_or_id)[0]
      results = ActiveFedora::Base.find(slug_or_id) if results.blank?
      results
    end

    def self.exact_slug_match(slug)
      # TODO: consider if we should change `slug_tesim` to `slug_ssim` so that a strict search is done
      # and we don't have to add the "select" method
      ActiveFedora::Base.where(slug_tesim: slug).select { |item| item.slug == slug }
    end

    # validate that the identifier creates a unique slug across all classes
    def check_slug
      return if identifier.empty?
      possible_duplicates = CustomSlugs::SlugBehavior.exact_slug_match(slug)
      has_duplicates = if new_record?
                         possible_duplicates.count.positive?
                       else
                         possible_duplicates.detect { |c| c.id != id }
                       end
      errors.add(:identifier, 'must be unique') if has_duplicates
    end

    def set_slug
      return if identifier.empty?
      self.slug = identifier.first.truncate(75, omission: '').parameterize.underscore
    end

    def remove_index_and_reindex
      # rubocop:disable Rails/Blank
      return unless slug.present?
      # rubocop:enable Rails/Blank

      # if we have a slug with an existing record, previous indexes would have a different id,
      # resulting extraneous solr indexes remaining (one fedora object with two solr indexes to it)
      #   1) This happens when a slug gets changed from either empty or a different value
      #   2) It also apparently happens in some situations where data existed prior to the slug logic
      # Testing for situation slug_changed? did not adequately prevent the second situation.
      # This query finds everything indexed by fedora id. The new index will have id: slug
      Blacklight.default_index.connection.delete_by_query('id:"' + id + '"')
      # This query finds everything else for this fedora id... if slug changed, may be something here.
      Blacklight.default_index.connection.delete_by_query('fedora_id_ssi:"' + id + '"')
      Blacklight.default_index.connection.commit
      update_index
    end
  end
end
