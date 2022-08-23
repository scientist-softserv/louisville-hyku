# frozen_string_literal: true

class GenericWork < ActiveFedora::Base
  include ::Hyrax::WorkBehavior
  include SetChildFlag

  validates :title, presence: { message: 'Your work must have a title.' }

  include ::Hyrax::BasicMetadata
  self.indexer = GenericWorkIndexer
  self.human_readable_type = 'Work'
end
