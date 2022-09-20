# frozen_string_literal: true

# @see app/models/custom_slugs/slug_README.md
RSpec.shared_examples "requires_slugs" do
  describe ".terms" do
    it 'requires identifier' do
      expect(form.primary_terms).to include(:identifier)
    end
  end
end
