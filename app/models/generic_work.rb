# frozen_string_literal: true

class GenericWork < ActiveFedora::Base
  include ::Hyrax::WorkBehavior
  include ::Hyrax::BasicMetadata

  validates :title, presence: { message: 'Your work must have a title.' }

  self.indexer = GenericWorkIndexer
  self.human_readable_type = 'Work'

  property :is_parent,
    predicate: ::RDF::URI.intern('https://hyku.library.louisville.edu/terms/isParent'),
    multiple: false do |index|
    index.as :stored_searchable
  end
end
