# frozen_string_literal: true

# Overrides newspaper_works 1.0.1 to allow update or create based on work state

module NewspaperWorks
  module Data
    module WorkFilesDecorator
      def commit_assigned
        return if @assigned.blank?
        ensure_depositor
        remote_files = @assigned.map do |path|
          { url: path_to_uri(path), file_name: File.basename(path) }
        end
        attrs = { remote_files: remote_files }
        # Create an environment for actor stack:
        env = Hyrax::Actors::Environment.new(@work, Ability.new(user), attrs)
        # Invoke default Hyrax actor stack middleware:
        @work.new_record? ? Hyrax::CurationConcern.actor.create(env) : Hyrax::CurationConcern.actor.update(env)
      end
    end
  end
end

NewspaperWorks::Data::WorkFiles.prepend(NewspaperWorks::Data::WorkFilesDecorator)
