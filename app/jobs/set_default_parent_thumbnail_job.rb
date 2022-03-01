# frozen_string_literal: true

class SetDefaultParentThumbnailJob < ApplicationJob
  queue_as :import

  def perform(parent_work:)
    parent_work.reload
    return if parent_work.thumbnail.present?

    curation_concerns = Hyrax.config.curation_concerns
    return unless curation_concerns.include?(parent_work.class)

    child_file_set = parent_work.child_works&.first&.file_sets&.first
    if child_file_set.nil?
      reschedule(parent_work: parent_work)
      return false # stop current job from continuing to run after rescheduling
    end

    parent_work.representative = child_file_set
    parent_work.thumbnail = child_file_set
    parent_work.save
  rescue StandardError
    nil # TODO: handle error messages
  end

  def reschedule(parent_work:)
    SetDefaultParentThumbnailJob.set(wait: 5.minutes).perform_later(parent_work: parent_work)
  end
end
