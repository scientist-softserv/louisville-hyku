# Generated via
#  `rails generate hyrax:work Art`
module Hyrax
  # Generated controller for Art
  class ArtsController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks
    self.curation_concern_type = ::Art

    # Use this line if you want to use a custom presenter
    self.show_presenter = Hyrax::ArtPresenter
  end
end
