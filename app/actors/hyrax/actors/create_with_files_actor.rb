# frozen_string_literal: true

# OVERRIDE: Hyrax 2.9.6 Add call to CreateJpgService and send result to attach files method
module Hyrax
  module Actors
    # Creates a work and attaches files to the work
    class CreateWithFilesActor < Hyrax::Actors::AbstractActor
      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create(env)
        uploaded_file_ids = filter_file_ids(env.attributes.delete(:uploaded_files))
        files = uploaded_files(uploaded_file_ids)
        # OVERRIDE: Hyrax: Split PDF into jpg for each page and sent to attach files method
        return false unless validate_files(files, env)
        return false unless next_actor.create(env)
        ConvertPdfToJpgJob.perform_later(files, env.curation_concern, env.attributes, env.user.id) if files.present?
        # END OVERRIDE
        attach_files(files, env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        uploaded_file_ids = filter_file_ids(env.attributes.delete(:uploaded_files))
        files = uploaded_files(uploaded_file_ids)
        # OVERRIDE: Hyrax: Split PDF into jpg for each page and sent to attach files method
        return false unless validate_files(files, env)
        return false unless next_actor.update(env)
        ConvertPdfToJpgJob.perform_later(files, env.curation_concern, env.attributes, env.user.id) if files.present?
        # END OVERRIDE
        attach_files(files, env)
      end

      private

        def filter_file_ids(input)
          Array.wrap(input).select(&:present?)
        end

        # ensure that the files we are given are owned by the depositor of the work
        def validate_files(files, env)
          expected_user_id = env.user.id
          files.each do |file|
            next if file.user_id == expected_user_id
            # rubocop:disable Metrics/LineLength
            Rails.logger.error "User #{env.user.user_key} attempted to ingest uploaded_file #{file.id}, but it belongs to a different user"
            # rubocop:enable Metrics/LineLength
            return false
          end
          true
        end

        # @return [TrueClass]
        def attach_files(files, env)
          return true if files.blank?
          AttachFilesToWorkJob.perform_later(env.curation_concern, files, env.attributes.to_h.symbolize_keys)
          true
        end

        # Fetch uploaded_files from the database
        def uploaded_files(uploaded_file_ids)
          return [] if uploaded_file_ids.empty?
          UploadedFile.find(uploaded_file_ids)
        end
    end
  end
end
