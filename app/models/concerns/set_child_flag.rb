# frozen_string_literal: true

module SetChildFlag
  extend ActiveSupport::Concern
  included do
    after_save :set_children
  end

  def set_children
    ordered_works.each do |child_work|
      child_work.update(is_child: true) unless child_work.is_child
    end
  end
end
