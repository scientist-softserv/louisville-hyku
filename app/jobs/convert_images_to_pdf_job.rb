# frozen_string_literal: true

class ConvertImagesToPdfJob < ApplicationJob
  retry_on NewspaperWorks::PagesNotReady,
           wait: :exponentially_longer,
           attempts: 15

  def perform(curation_concern)
    Sidekiq.logger.error("ConvertImagesToPdfJob is starting #{Time.now.utc} :: curation_concern.id #{curation_concern.id}") # rubocop: disable Metrics/LineLength
    PDFComposer.new(curation_concern).compose
    Sidekiq.logger.error("ConvertImagesToPdfJob is ending #{Time.now.utc} :: curation_concern.id #{curation_concern.id}") # rubocop: disable Metrics/LineLength
  end
end
