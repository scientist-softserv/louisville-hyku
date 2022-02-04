# frozen_string_literal: true

module Hyrax
  module WorkShowPresenterDecorator
    # OVERRIDE: Hyrax 2.9.6
    def total_pages(members = nil)
      # if we're hiding the derivatives, we won't have as many pages to show
      pages = members.presence || total_items

      (pages.to_f / rows_from_params.to_f).ceil
    end
  end
end

Hyrax::WorkShowPresenter.prepend(Hyrax::WorkShowPresenterDecorator)
