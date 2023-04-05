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
      solr_doc['file_set_ids_ssim'] = all_decendent_file_sets(object)
    end
  end

  def all_decendent_file_sets(o)
    # enables us to return parents when searching for child OCR
    all_my_children = o.file_sets.map(&:id)
    o.ordered_works&.each do |child|
      all_my_children += all_decendent_file_sets(child)
    end
    # enables us to return parents when searching for child metadata
    all_my_children << o.members.map(&:to_param)
    all_my_children.flatten!.uniq.compact
  end

  def ancestor_ids(o)
    a_ids = []
    o.in_works.each do |work|
      a_ids << work.to_param
      a_ids += ancestor_ids(work) if work.is_child
    end
    a_ids
  end
end
