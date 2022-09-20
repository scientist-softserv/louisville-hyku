# frozen_string_literal: true

# @see app/models/custom_slugs/slug_README.md
RSpec.shared_examples 'object includes slugs' do
  it 'includes slug terms' do
    expect(this_object.identifier).to be_present
    expect(this_object.slug).to be_present
  end
end
