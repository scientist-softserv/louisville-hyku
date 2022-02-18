module Bulkrax
  module CreateRelationshipsJobDecorator
    # OVERRIDE: Bulkrax v.2.2
    def perform(entry_identifier:, parent_identifier: nil, child_identifier: nil, importer_run:)
      @base_entry = Entry.find_by(identifier: entry_identifier)
      @importer_run = importer_run
      if parent_identifier.present?
        @child_record = find_record(entry_identifier)
        @parent_record = find_record(parent_identifier)
      elsif child_identifier.present?
        @parent_record = find_record(entry_identifier)
        @child_record = find_record(child_identifier)
      else
        raise ::StandardError, %("#{entry_identifier}" needs either a child or a parent to create a relationship)
      end

      if @child_record.blank? || @parent_record.blank?
        reschedule(
          entry_identifier: entry_identifier,
          parent_identifier: parent_identifier,
          child_identifier: child_identifier,
          importer_run: importer_run
        )
        return false # stop current job from continuing to run after rescheduling
      end

      create_relationship
      # OVERRIDE Bulkrax 2.2 to set parent thumbnail when its file_set is nil
      SetParentThumbnailJob.perform_later(parent_work: @parent_record, child_work: @child_record)
    rescue ::StandardError => e
      base_entry.status_info(e)
      importer_run.increment!(:failed_relationships) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end

Bulkrax::CreateRelationshipsJob.prepend(Bulkrax::CreateRelationshipsJobDecorator)