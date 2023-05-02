# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Text`
module Hyrax
  module Actors
    class TextActor < Hyrax::Actors::BaseActor
      # TODO: Remove after Fedora data migration
      # Prevent :file_set_ids_to_restore from being passed to
      # BaseActor#apply_save_data_to_curation_concern. It is not a
      # metadata property and is meant to be only used when migrating Fedora.
      # @see lib/tasks/migrate_fedora.rake
      def clean_attributes(attributes)
        clean_attrs = super
        clean_attrs.except(:file_set_ids_to_restore)
      end
    end
  end
end
