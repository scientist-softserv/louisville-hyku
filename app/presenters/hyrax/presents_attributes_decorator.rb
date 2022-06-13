# frozen_string_literal: true

# OVERRIDE: Hyrax 2.9.6 to not display properties with empty values

module Hyrax
  module PresentsAttributesDecorator
    def attribute_to_html(field, options = {})
      unless respond_to?(field)
        Rails.logger.warn("#{self.class} attempted to render #{field}, but no method exists with that name.")
        return
      end

      # OVERRIDE: Hyrax 2.9.6 to not display properties with empty values
      return unless send(field)&.first&.present?

      if options[:html_dl]
        renderer_for(field, options).new(field, send(field), options).render_dl_row
      else
        renderer_for(field, options).new(field, send(field), options).render
      end
    end
  end
end

Hyrax::PresentsAttributes.prepend(Hyrax::PresentsAttributesDecorator)
