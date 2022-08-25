# frozen_string_literal: true

module SetChildFlag
  extend ActiveSupport::Concern
  included do
    after_save :set_children
    property :is_child,
             predicate: ::RDF::URI.intern("https://#{ENV.fetch('HYKU_ROOT_HOST', 'hyku.library.louisville.edu')}
             /terms/isChild"),
             multiple: false do |index|
               index.as :stored_searchable
             end
  end

  def set_children
    ordered_works.each do |child_work|
      child_work.update(is_child: true) unless child_work.is_child
    end
  end
end
