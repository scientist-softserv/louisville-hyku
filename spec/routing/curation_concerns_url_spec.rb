# frozen_string_literal: true

# specs for custom slug behaviors
# @see app/models/custom_slugs/slug_README.md
RSpec.describe '/concern/generic_works routing', clean: true do
  let(:work) { create(:generic_work) }

  context 'without custom slug' do
    it "routes to work by UUID" do
      expect(get: "/concern/generic_works/#{work.id}")
        .to route_to(controller: 'hyrax/generic_works', action: 'show', id: work.id.to_s)
    end
  end

  context 'with custom slug' do
    let(:custom_slug) { "My Custom Slug" }
    let(:slug_parameter) { custom_slug.downcase.parameterize.underscore }

    before do
      work.slug = custom_slug
      work.save
    end

    it "routes to work by UUID" do
      expect(get: "/concern/generic_works/#{work.id}")
        .to route_to(controller: 'hyrax/generic_works', action: 'show', id: work.id.to_s)
    end

    it "routes to work by custom slug" do
      expect(get: "/concern/generic_works/#{slug_parameter}")
        .to route_to(controller: 'hyrax/generic_works', action: 'show', id: slug_parameter)
    end
  end
end
