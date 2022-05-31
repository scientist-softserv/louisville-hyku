# frozen_string_literal: true

# OVERRIDE Hyrax 2.9.6 to use the display_media_download_link? method
module Hyrax
  module FileSetHelperDecorator
    def display_media_download_link?(file_set:)
      Hyrax.config.display_media_download_link? &&
        # OVERRIDE Hyrax 2.9.6 to restrict showing the download link to admin's only
        current_user.admin? &&
        !workflow_restriction?(file_set.try(:parent))
    end
  end
end

Hyrax::FileSetHelper.prepend(Hyrax::FileSetHelperDecorator)
