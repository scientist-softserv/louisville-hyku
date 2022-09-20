# frozen_string_literal: true

module CustomSlugs
  # This is an internal application-only custom identifier for the use of slugs'
  # It is important not to reuse any terms on the fedora items, as one would overwrite the other.
  # This creates an internal term specifically for slug use which will never get overwritten.
  # @see app/models/custom_slugs/slug_README.md

  class CustomSlugsTerm < RDF::Vocabulary('http://id.loc.gov/vocabulary/identifiers/')
    property 'slug'
  end
end
