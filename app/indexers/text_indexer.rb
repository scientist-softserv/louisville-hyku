# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Text`
class TextIndexer < Hyrax::WorkIndexer
  # This indexes the default metadata. You can remove it if you want to
  # provide your own metadata and indexing.
  include Hyrax::IndexesBasicMetadata

  # Fetch remote labels for based_near. You can remove this if you don't want
  # this behavior
  include Hyrax::IndexesLinkedMetadata

  # Uncomment this block if you want to add custom indexing behavior:
  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc['all_text_tsimv'] = [object.searchable_text]
      solr_doc['is_page_of_ssim']         = ancestor_ids(object)
    end
  end

  def ancestor_ids(o)
    a_ids = []
    o.in_works.each do |work|
      a_ids << work.id
      a_ids += ancestor_ids(work) unless work.is_parent
    end
    a_ids
  end
end
