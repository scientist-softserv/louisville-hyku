# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Text`
class TextIndexer < AppIndexer

  # Uncomment this block if you want to add custom indexing behavior:
  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc['all_text_tsimv'] = [object.searchable_text]
    end
  end
end
