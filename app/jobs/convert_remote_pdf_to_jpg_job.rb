# frozen_string_literal: true

class ConvertRemotePdfToJpgJob < ApplicationJob
  def perform(file, curation_concern, attributes, user)
    jpg_files = CreateJpgService.new(file, user, cached: false).create_jpgs_from_remote_pdf
    return true if jpg_files.blank?
    AttachFilesToWorkJob.perform_now(curation_concern, jpg_files, attributes.to_h.symbolize_keys)
    DeleteJpgFilesJob.perform_later(jpg_files)
  end
end
