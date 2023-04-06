# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Image`

RSpec.describe Image do
  describe 'indexer' do
    subject { described_class.indexer }

    it { is_expected.to eq ImageIndexer }
  end

  describe 'with custom slugs' do
    let!(:this_object) { create(:image) }
    let(:that_object) { create(:image, identifier: ["#{this_object.identifier.first}s"]) }

    include_examples("object includes slugs")
  end
end
