class SetParentThumbnailJob < ApplicationJob
  # queue_as Hyrax.config.ingest_queue_name
  queue_as :import

  def perform(parent_work:, child_work:)
    child_file_sets = child_work.file_sets
    if child_file_sets.empty?
      reschedule(parent_work: parent_work, child_work: child_work) 
      return false # stop current job from continuing to run after rescheduling
    end
    
    return unless parent_work.present? && child_file_sets.present?
    return if parent_work.thumbnail.present?

    curation_concerns = Hyrax.config.curation_concerns
    return unless curation_concerns.include? (parent_work.class)

    parent_work.representative = child_file_sets.first
    parent_work.thumbnail = child_file_sets.first
    parent_work.rendering_ids << child_work.id
    parent_work.save
  rescue StandardError
    nil #TODO: handle error messages
  end

  def reschedule(parent_work:, child_work:)
    SetParentThumbnailJob.set(wait: 10.minutes).perform_later(parent_work: parent_work, child_work: child_work)
  end
end
