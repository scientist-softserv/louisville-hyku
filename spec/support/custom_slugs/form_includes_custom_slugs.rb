# frozen_string_literal: true

# @see app/models/custom_slugs/slug_README.md
RSpec.shared_examples "custom_slugs" do
  describe ".terms" do
    it 'includes the identifier field' do
      expect(form.terms).to include(:identifier)
    end
  end
end
