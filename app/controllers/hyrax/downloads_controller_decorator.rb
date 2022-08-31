# frozen_string_literal: true

# OVERRIDE Hyrax 2.9.6 to edit file type access

module Hyrax
  module DownloadsControllerDecorator
    # OVERRIDE Hyrax 2.9.6 to allow all users to access thumbnails
    # and only admin users to access other file derivatives
    def show
      case file
      when ActiveFedora::File
        # For original files that are stored in fedora
        super
      when String
        # For derivatives stored on the local file system
        if file.include?('thumbnail') || current_user&.is_admin?
          send_local_content
        else
          redirect_back fallback_location: main_app.root_url, alert: 'You are unauthorized to access that file.'
        end
      else
        raise Hyrax::ObjectNotFoundError
      end
    end
  end
end

Hyrax::DownloadsController.prepend(Hyrax::DownloadsControllerDecorator)
