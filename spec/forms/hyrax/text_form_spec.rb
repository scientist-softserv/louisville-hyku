# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Text`
require 'rails_helper'

RSpec.describe Hyrax::TextForm do
  let(:work) { Text.new }
  let(:form) { described_class.new(work, nil, nil) }

  include_examples("custom_slugs")
  include_examples("requires_slugs")
end
