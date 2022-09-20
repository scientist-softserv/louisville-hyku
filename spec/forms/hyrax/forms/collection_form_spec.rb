# frozen_string_literal: true

RSpec.describe Hyrax::Forms::CollectionForm do
  let(:collection) { create(:collection) }
  let(:form) { described_class.new(collection, nil, nil) }

  include_examples("custom_slugs")
  include_examples("requires_slugs")
end
