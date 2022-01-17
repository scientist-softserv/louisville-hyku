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
    end
  end

  ::Bulkrax::ObjectFactory.prepend(Bulkrax::ObjectFactoryDecorator)
end
