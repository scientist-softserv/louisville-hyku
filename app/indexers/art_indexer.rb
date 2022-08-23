# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Art`
class ArtIndexer < AppIndexer
  # Uncomment this block if you want to add custom indexing behavior:
  # def generate_solr_document
  #   super.tap do |solr_doc|
  #     solr_doc[Solrizer.solr_name('account_cname')] = Site.instance&.account&.cname
  #   end
  # end
end
