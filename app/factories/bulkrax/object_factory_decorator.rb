# frozen_string_literal: true

# Add ability to mark environment as from bulk import
# fix for treeified error on import
if ENV.fetch('HYKU_BULKRAX_ENABLED', false)
  module Bulkrax
    module ObjectFactoryDecorator
      # @param [Hash] attrs the attributes to put in the environment
      # @return [Hyrax::Actors::Environment]
      def environment(attrs)
        Hyrax::Actors::Environment.new(object, Ability.new(@user), attrs, true)
      end

      def find
        # rubocop:disable Rails/DynamicFindBy
        return find_by_id if attributes[:id].present?
        # rubocop:enable Rails/DynamicFindBy
        return search_by_identifier if attributes[work_identifier].present?
      end

      # TODO: documentation
      def permitted_attributes
        permitted_attrs = super
        permitted_attrs += [:file_set_ids_to_restore]
      end
    end
  end

  ::Bulkrax::ObjectFactory.prepend(Bulkrax::ObjectFactoryDecorator)
end
