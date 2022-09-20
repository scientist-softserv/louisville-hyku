# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Art`
require 'rails_helper'

RSpec.describe Hyrax::ArtForm do
  let(:work) { Text.new }
  let(:form) { described_class.new(work, nil, nil) }

  include_examples("work_form")
  include_examples("custom_slugs")
  include_examples("requires_slugs")
end
