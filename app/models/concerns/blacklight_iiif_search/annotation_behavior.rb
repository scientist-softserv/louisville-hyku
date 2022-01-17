# frozen_string_literal: true

# customizable behavior for IiifSearch
module BlacklightIiifSearch
  module AnnotationBehavior
    include NewspaperWorks::BlacklightIiifSearch::AnnotationBehavior
    def file_set_id
      # rubocop:disable Metrics/LineLength
      file_set_ids = document['has_model_ssim'].include?("FileSet") ? Array.wrap(document['id']) : document['file_set_ids_ssim']
      # rubocop:enable Metrics/LineLength
      raise "#{self.class}: NO FILE SET ID" if file_set_ids.blank?
      file_set_ids.first
    end
  end
end
