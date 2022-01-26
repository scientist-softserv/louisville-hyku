# frozen_string_literal: true

<<<<<<< HEAD:app/indexers/art_indexer.rb
# Generated via
#  `rails generate hyrax:work Art`
class ArtIndexer < Hyrax::WorkIndexer
=======
class AppIndexer < Hyrax::WorkIndexer
>>>>>>> d787fca048e7563d4376fe3df05e4e71ffbec378:app/indexers/app_indexer.rb
  # This indexes the default metadata. You can remove it if you want to
  # provide your own metadata and indexing.
  include Hyrax::IndexesBasicMetadata

  # Fetch remote labels for based_near. You can remove this if you don't want
  # this behavior
  include Hyrax::IndexesLinkedMetadata

  # Uncomment this block if you want to add custom indexing behavior:
  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc[Solrizer.solr_name('account_cname')] = Site.instance&.account&.cname
    end
  end
end
