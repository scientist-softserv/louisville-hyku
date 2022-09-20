# frozen_string_literal: true

# @see app/models/custom_slugs/slug_README.md
RSpec.shared_examples "indexes_custom_slugs" do
  describe "generate_solr_document" do
    it 'includes the custom slug fields' do
      expect(solr_document.fetch("fedora_id_ssi")).to be_present
      expect(solr_document.fetch("slug_tesim")).to be_present
    end
  end
end
