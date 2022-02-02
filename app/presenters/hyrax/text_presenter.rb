# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Text`
module Hyrax
  class TextPresenter < Hyku::WorkShowPresenter
    # Adds behaviors for hyrax-doi plugin.
    # include Hyrax::DOI::DOIPresenterBehavior

    # OVERRIDE: Hyrax 2.9.6
    def total_pages(members = nil)
      # if we're hiding the derivatives, we won't have as many pages to show
      pages = members.presence || total_items

      (pages.to_f / rows_from_params.to_f).ceil
    end
  end
end
