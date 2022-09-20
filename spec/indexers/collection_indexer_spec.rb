# frozen_string_literal: true

RSpec.describe CollectionIndexer do
  subject(:solr_document) { service.generate_solr_document }

  let(:service) { described_class.new(collection) }
  let(:collection) { create(:collection) }

  include_examples("indexes_custom_slugs")
end
