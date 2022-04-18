# frozen_string_literal: true

# OVERRIDE: Bulkrax v.3.0

module Bulkrax
  module CreateRelationshipsJobDecorator
    attr_accessor :child_records, :parent_record, :parent_entry, :importer_run_id

    def create_relationships
      if parent_record.is_a?(::Collection)
        collection_parent_work_child unless child_records[:works].empty?
        collection_parent_collection_child unless child_records[:collections].empty?
      else
        work_parent_work_child unless child_records[:works].empty?
        # OVERRIDE: Bulkrax v.3.0
        parent_record.update(is_parent: true)
        # set the first child's thumbnail as the thumbnail for the parent
        ::SetDefaultParentThumbnailJob.set(wait: 10.minutes)
                                      .perform_later(parent_work: parent_record, importer_run_id: importer_run_id)

        if child_records[:collections].present?
          raise ::StandardError, 'a Collection may not be assigned as a child of a Work'
        end
      end
    end
  end
end

Bulkrax::CreateRelationshipsJob.prepend(Bulkrax::CreateRelationshipsJobDecorator)
