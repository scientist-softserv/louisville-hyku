# frozen_string_literal: true

module Bulkrax
  # TODO: Delete file once relationships are recreated
  #
  # This job is a spin-off of Bulkrax::CreateRelationshipsJob. Its purpose is to reconnect records to each other
  # post-Fedora migration. This job is needed for a one-time operation and should be deleted once it's no longer
  # needed.
  class RestoreMigratedRelationshipsJob < ApplicationJob
    queue_as :default

    attr_accessor :child_records, :parent_record

    # @param String parent_identifier Parent record's slug
    # @param String child_identifiers Slugs of records to add as children to parent
    def perform(parent_identifier:, child_identifiers:)
      @parent_record = ActiveFedora::Base.where(identifier_ssi: parent_identifier).first
      raise StandardError, "Parent #{parent_identifier} does not exist" if parent_record.nil?

      @child_records = { works: [], collections: [] }
      pending_relationship_ids = []
      child_identifiers.each do |ci|
        pending_relationship_ids << rel.id
        rel = Bulkrax::PendingRelationship.find_by(parent_id: parent_identifier, child_id: ci)
        raise ::StandardError, %("#{rel}" needs either a child or a parent to create a relationship) if rel.child_id.nil? || rel.parent_id.nil?

        child_record = ActiveFedora::Base.where(identifier_ssi: rel.child_id).first
        if child_record
          next if parent_record.member_ids.include?(child_record.id)
          next if parent_record.member_collection_ids.include?(child_record.id) if parent_record.respond_to?(:member_collection_ids)
          next if child_record.member_of_collection_ids.include?(parent_record.id)

          child_record.is_a?(::Collection) ? @child_records[:collections] << child_record : @child_records[:works] << child_record
        end
      end

      raise StandardError, "No children found for #{parent_identifier}" if (child_records[:collections].blank? && child_records[:works].blank?)
      create_relationships
      pending_relationship_ids.each do |id|
        Bulkrax::PendingRelationship.find(id).destroy
      end
    end

    private

    def create_relationships
      if parent_record.is_a?(::Collection)
        collection_parent_work_child unless child_records[:works].empty?
        collection_parent_collection_child unless child_records[:collections].empty?
      else
        work_parent_work_child unless child_records[:works].empty?
        child_records[:works].each do |work|
          # reindex filesets to update solr's is_page_of_ssim
          work.file_sets.each(&:update_index)
        end

        if child_records[:collections].present?
          raise ::StandardError, 'a Collection may not be assigned as a child of a Work'
        end
      end
    end

    def user
      @user ||= Bulkrax::Importer.last.user
    end

    # Work-Collection membership is added to the child as member_of_collection_ids
    # This is adding the reverse relationship, from the child to the parent
    def collection_parent_work_child
      child_work_ids = child_records[:works].map(&:id)
      parent_record.reindex_extent = Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX

      parent_record.add_member_objects(child_work_ids)
    end

    # Collection-Collection membership is added to the as member_ids
    def collection_parent_collection_child
      child_records[:collections].each do |child_record|
        ::Hyrax::Collections::NestedCollectionPersistenceService.persist_nested_collection_for(parent: parent_record, child: child_record)
      end
    end

    # Work-Work membership is added to the parent as member_ids
    def work_parent_work_child
      records_hash = {}
      child_records[:works].each_with_index do |child_record, i|
        records_hash[i] = { id: child_record.id }
      end
      attrs = { work_members_attributes: records_hash }
      parent_record.try(:reindex_extent=, Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX)
      env = Hyrax::Actors::Environment.new(parent_record, Ability.new(user), attrs)

      Hyrax::CurationConcern.actor.update(env)
    end
  end
end
