# frozen_string_literal: true

class ReindexCollectionsJob < ApplicationJob
  def perform(collection = nil)
    if collection.present?
      collection.update_index
    else
      Collection.find_each do |col|
        col.reindex_extent = Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX
        col.update_index
      end
    end
  end
end
