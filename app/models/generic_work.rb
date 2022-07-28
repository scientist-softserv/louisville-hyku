# frozen_string_literal: true

class GenericWork < ActiveFedora::Base
  include ::Hyrax::WorkBehavior
  include SetChildFlag

  validates :title, presence: { message: 'Your work must have a title.' }

  property :is_child,
           predicate: ::RDF::URI.intern('https://hyku.library.louisville.edu/terms/isChild'),
           multiple: false do |index|
    index.as :stored_searchable
  end

  include ::Hyrax::BasicMetadata
  self.indexer = GenericWorkIndexer
  self.human_readable_type = 'Work'
end
