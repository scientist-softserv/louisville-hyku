# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Collection do
  it "is a hyrax collection" do
    expect(described_class.ancestors).to include Hyrax::CollectionBehavior
  end

  describe ".indexer" do
    subject { described_class.indexer }

    it { is_expected.to eq CollectionIndexer }
  end

  describe 'with custom slugs' do
    let!(:this_object) { create(:collection) }
    let(:that_object) { create(:collection, identifier: ["#{this_object.identifier.first}s"]) }

    include_examples("object includes slugs")
  end
end
