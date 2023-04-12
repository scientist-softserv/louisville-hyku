# frozen_string_literal: true

# @see app/models/custom_slugs/slug_README.md
RSpec.shared_examples 'object includes slugs' do
  it 'includes slug terms' do
    expect(this_object.identifier).to be_present
    expect(this_object.slug).to be_present
  end

  it 'finds the correct work when searching by slug' do
    expect(CustomSlugs::SlugBehavior.exact_slug_match(this_object.slug).first).to eq(this_object)
    expect(CustomSlugs::SlugBehavior.exact_slug_match(that_object.slug).first).to eq(that_object)
  end
end
