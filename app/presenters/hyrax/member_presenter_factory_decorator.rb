# frozen_string_literal: true

module Hyrax
  module MemberPresenterFactoryDecorator
    # OVERRIDE: Hyrax 2.9.6
    def ordered_ids
      # TODO(alishaevn): remove this decorator override
      # when the CreateRelationshipsJob is fixed in Bulkrax 2.0+
      Hyrax::SolrDocument::OrderedMembers.decorate(@work).member_ids
    end
  end
end

Hyrax::MemberPresenterFactory.prepend(Hyrax::MemberPresenterFactoryDecorator)
