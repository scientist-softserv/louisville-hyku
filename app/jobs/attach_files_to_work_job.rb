# frozen_string_literal: true

# OVERRIDE: Hyrax 2.9.6 to add derived to uploaded files

class AttachFilesToWorkJob < Hyrax::ApplicationJob
  include Hyrax::Lockable
  queue_as Hyrax.config.ingest_queue_name

  # @param [ActiveFedora::Base] work - the work object
  # @param [Array<Hyrax::UploadedFile>] uploaded_files - an array of files to attach
  # rubocop:disable Metrics/AbcSize
  def perform(work, uploaded_files, **work_attributes)
    Sidekiq.logger.error("AttachFilesToWorkJob is starting #{Time.now.utc} :: Work ID #{work.id}") # rubocop: disable Metrics/LineLength
    validate_files!(uploaded_files)
    depositor = proxy_or_depositor(work)
    user = User.find_by_user_key(depositor)
    work_permissions = work.permissions.map(&:to_hash)
    metadata = visibility_attributes(work_attributes)
    visibility_attributes(work_attributes)
    actors = []
    file_set_ids = work_attributes[:file_set_ids]
    uploaded_files.in_groups_of(10, false) do |upload_group|
      upload_group.each do |uploaded_file|
        next if uploaded_file.file_set_uri.present?
        Sidekiq.logger.error("uploaded files block is starting #{Time.now.utc} :: Work ID #{work.id}")
        created_file_set = if file_set_ids.present?
                             file_set_id = file_set_ids.shift
                             FileSet.create(id: file_set_id)
                           else
                             FileSet.create
                           end
        actor = Hyrax::Actors::FileSetActor.new(created_file_set, user)
        uploaded_file.update(file_set_uri: actor.file_set.uri)
        actor.file_set.permissions_attributes = work_permissions
        metadata[:is_derived] = uploaded_file.derived?
        actor.create_metadata(metadata)
        actor.create_content(uploaded_file)
        actor.file_set.visibility = work.visibility
        actors << actor
        Sidekiq.logger.error("uploaded files block is ending #{Time.now.utc} :: Work ID #{work.id}")
      end
    end

    attach_to_work(actors, work)

    works_that_dont_need_pdf = Hyrax.config.curation_concerns
    ConvertImagesToPdfJob.perform_later(work) unless works_that_dont_need_pdf.include?(work.class)
    Sidekiq.logger.error("AttachFilesToWorkJob is ending #{Time.now.utc} :: Work ID #{work.id}") # rubocop: disable Metrics/LineLength
    true
  end
  # rubocop:enable Metrics/AbcSize

  private

    def attach_to_work(actors, work)
      acquire_lock_for(work.id) do
        members = work.ordered_members
        pdf = nil
        actors.each do |a|
          pdf = a.file_set if pdf.blank? && a.file_set.label.match(/.pdf/)
          if a.file_set.label =~ /.jpg/
            work.representative = a.file_set if work.representative.blank?
            work.thumbnail = a.file_set if work.thumbnail.blank?
          end

          members << a.file_set
        end
        work.rendering_ids = [pdf.id] if pdf.present?
        work.save
      end
    end

    # The attributes used for visibility - sent as initial params to created FileSets.
    def visibility_attributes(attributes)
      attributes.slice(:visibility, :visibility_during_lease,
                       :visibility_after_lease, :lease_expiration_date,
                       :embargo_release_date, :visibility_during_embargo,
                       :visibility_after_embargo)
    end

    def validate_files!(uploaded_files)
      uploaded_files.each do |uploaded_file|
        next if uploaded_file.is_a? Hyrax::UploadedFile
        raise ArgumentError,
              "Hyrax::UploadedFile required, but #{uploaded_file.class} received: #{uploaded_file.inspect}"
      end
    end

    ##
    # A work with files attached by a proxy user will set the depositor as the intended user
    # that the proxy was depositing on behalf of. See tickets #2764, #2902.
    def proxy_or_depositor(work)
      # rubocop:disable Rails/Presence
      work.on_behalf_of.blank? ? work.depositor : work.on_behalf_of
      # rubocop:enable Rails/Presence
    end
end
