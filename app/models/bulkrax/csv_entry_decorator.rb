# frozen_sting_literal: true

# OVERRIDE BULKRAX 2.2.4 to split on semicolon only
module Bulkrax
  module CsvEntryDecorator
    def possible_collection_ids
      ActiveSupport::Deprecation.warn(
        'Creating Collections using the collection_field_mapping will no longer be supported as of Bulkrax version 3.0.' \
        ' Please configure Bulkrax to use related_parents_field_mapping and related_children_field_mapping instead.'
      )
      @possible_collection_ids ||= record.inject([]) do |memo, (key, value)|
        # OVERRIDE BULKRAX 2.2.4 to split on semicolon only
        memo += value.split(/\s*[;|]\s*/) if self.class.collection_field.to_s == key_without_numbers(key) && value.present?
        memo
      end || []
    end
  end
end

Bulkrax::CsvEntry.prepend(Bulkrax::CsvEntryDecorator)