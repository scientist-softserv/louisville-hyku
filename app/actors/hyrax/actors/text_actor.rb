# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Text`
module Hyrax
  module Actors
    class TextActor < Hyrax::Actors::BaseActor
      # TODO: documentation
      def clean_attributes(attributes)
        clean_attrs = super
        clean_attrs.except(:file_set_ids)
      end
    end
  end
end
