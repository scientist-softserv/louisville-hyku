# frozen_string_literal: true

class AppIndexer < Hyrax::WorkIndexer
  # This indexes the default metadata. You can remove it if you want to
  # provide your own metadata and indexing.
  include Hyrax::IndexesBasicMetadata

  # Fetch remote labels for based_near. You can remove this if you don't want
  # this behavior
  include Hyrax::IndexesLinkedMetadata

  include CustomSlugs::SlugIndexer

  # Uncomment this block if you want to add custom indexing behavior:
  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc[Solrizer.solr_name('account_cname')] = Site.instance&.account&.cname
      solr_doc['is_child_bsi'] = object.is_child
      solr_doc['title_ssi'] = object.title.first
      solr_doc['identifier_ssi'] = object.identifier.first
      solr_doc['is_page_of_ssim'] = ancestor_ids(object)
      solr_doc['file_set_ids_ssim'] = descendent_member_ids_for(object)
    end
  end

  def descendent_member_ids_for(object)
    # enables us to return parents when searching for child OCR
    file_set_ids_array = object.file_sets.map(&:id)
    object.ordered_works&.each do |child|
      file_set_ids_array += descendent_member_ids_for(child)
    end
    # enables us to return parents when searching for child metadata
    file_set_ids_array << object.members.map(&:to_param)
    file_set_ids_array.flatten.uniq.compact
  end

  def ancestor_ids(object)
    ancestor_ids_array = []
    object.in_works.each do |work|
      ancestor_ids_array << work.to_param
      ancestor_ids_array += ancestor_ids(work) if work.is_child
    end
    ancestor_ids_array << object.members.map(&:to_param)
    ancestor_ids_array.flatten.uniq.compact
  end
end
