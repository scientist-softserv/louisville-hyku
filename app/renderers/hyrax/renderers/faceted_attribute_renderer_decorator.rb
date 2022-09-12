# frozen_string_literal: true

module Hyrax
  module Renderers
    module FacetedAttributeRendererDecorator
      private

        def search_path(value)
          path = Rails.application.routes.url_helpers.search_catalog_path(
            :"f[#{search_field}][]" => value, locale: I18n.locale
          )
          path += '&include_child_works=true' if options[:is_child_bsi] == true
          path
        end
    end
  end
end

Hyrax::Renderers::FacetedAttributeRenderer.prepend(Hyrax::Renderers::FacetedAttributeRendererDecorator)
