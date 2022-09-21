# frozen_string_literal: true

module CustomSlugs
  # helper methods to convert to/from slugs to fedora ids
  # @see app/models/custom_slugs/slug_README.md

  module Manipulations
    ##
    # @param identifier_or_slug [String]
    # @return [String] an object identifer if one exists
    # @return [String] the given value if none exists
    # @see CustomSlugs.cast_to_slug
    def self.cast_to_identifier(identifier_or_slug)
      object = ActiveFedora::Base.find(identifier_or_slug)
      # All objects have an id property but we may not have found an object.
      object&.id || identifier_or_slug
    rescue Ldp::Gone
      identifier_or_slug
    end

    ##
    # @param identifier_or_slug [String]
    # @return [String] a slug if one exists
    # @return [String] the given value if none exists
    # @see CustomSlugs.cast_to_identifier
    def self.cast_to_slug(identifier_or_slug)
      object = ActiveFedora::Base.find(identifier_or_slug)
      # Not all objects will have a slug property.
      return identifier_or_slug unless object.respond_to?(:slug)
      object.slug.presence || identifier_or_slug
    rescue Ldp::Gone
      identifier_or_slug
    end

    ##
    # @param ids [Array]
    # @return [Array] of identifier_or_slug
    # @see CustomSlugs.cast_to_slug
    def self.cast_to_slug_or_ids_for(ids)
      slug_or_ids = []
      ids.each do |id|
        slug_or_ids << cast_to_slug(id)
      end
      slug_or_ids
    end
  end
end
