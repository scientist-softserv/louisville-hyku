# frozen_string_literal: true

# OVERRIDE: Hyrax 2.9.1 to change all_text_tsimv to all_text_timv
# Would like the OCR text to display in search results
# so it needs to be a stored value

module Hyrax
  class FileSetIndexer < ActiveFedora::IndexingService
    include Hyrax::IndexesThumbnails
    include Hyrax::IndexesBasicMetadata
    include NewspaperWorks::IndexesFullText

    STORED_LONG = Solrizer::Descriptor.new(:long, :stored)

    # rubocop:disable Metrics/AbcSize
    def generate_solr_document
      super.tap do |solr_doc|
        solr_doc['hasRelatedMediaFragment_ssim'] = object.representative_id
        solr_doc['hasRelatedImage_ssim'] = object.thumbnail_id
        # Label is the actual file name. It's not editable by the user.
        solr_doc['label_tesim'] = object.label
        solr_doc['label_ssi']   = object.label
        solr_doc['file_format_tesim'] = file_format
        solr_doc['file_format_sim']   = file_format
        solr_doc['file_size_lts'] = object.file_size[0]
        # OVERRIDE Hyrax 2.9.1 to make OCR data stored value for display
        solr_doc['all_text_tsimv'] = object.extracted_text.content if object.extracted_text.present?
        solr_doc['height_is'] = Integer(object.height.first) if object.height.present?
        solr_doc['width_is']  = Integer(object.width.first) if object.width.present?
        solr_doc['visibility_ssi'] = object.visibility
        solr_doc['mime_type_ssi']  = object.mime_type
        # Index the Fedora-generated SHA1 digest to create a linkage between
        # files on disk (in fcrepo.binary-store-path) and objects in the repository.
        solr_doc['digest_ssim'] = digest_from_content
        solr_doc['page_count_tesim']        = object.page_count
        solr_doc['file_title_tesim']        = object.file_title
        solr_doc['duration_tesim']          = object.duration
        solr_doc['sample_rate_tesim']       = object.sample_rate
        solr_doc['original_checksum_tesim'] = object.original_checksum
        solr_doc['alpha_channels_ssi']      = object.try(:alpha_channels)
        solr_doc['original_file_id_ssi']    = original_file_id
        solr_doc['is_derived_ssi']          = object.is_derived
        # only UV viewable images should have is_page_of, it is only used for iiif search
        solr_doc['is_page_of_ssim']         = [ancestor_ids(object)] if object.mime_type&.match(/image/)
        index_full_text(object, solr_doc)
      end
    end
    # rubocop:enable Metrics/AbcSize

    private

      def ancestor_ids(object)
        ancestor_ids_array = []
        object.in_works.each do |work|
          ancestor_ids_array << work.to_param
          ancestor_ids_array += ancestor_ids(work) if work.is_child
        end

        # flatten nested array
        ancestor_ids_array.flatten.uniq.compact
      end

      def digest_from_content
        return unless object.original_file
        object.original_file.digest.first.to_s
      end

      def original_file_id
        return unless object.original_file
        if object.original_file.versions.present?
          ActiveFedora::File.uri_to_id(object.current_content_version_uri)
        else
          object.original_file.id
        end
      end

      # rubocop:disable Rails/Presence
      def file_format
        if object.mime_type.present? && object.format_label.present?
          "#{object.mime_type.split('/').last} (#{object.format_label.join(', ')})"
        elsif object.mime_type.present?
          object.mime_type.split('/').last
        elsif object.format_label.present?
          object.format_label
        end
      end
    # rubocop:enable Rails/Presence
  end
end
