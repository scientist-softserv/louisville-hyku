# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Text`
require 'rails_helper'

RSpec.describe Text do
  describe 'indexer' do
    subject { described_class.indexer }

    it { is_expected.to eq TextIndexer }
  end

  describe 'with custom slugs' do
    let!(:this_object) { create(:text) }
    let(:that_object) { create(:text, identifier: ["#{this_object.identifier.first}s"]) }

    include_examples("object includes slugs")
  end
end
