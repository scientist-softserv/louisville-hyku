# frozen_string_literal: true

# OVERRIDE hydra-works v.1.2.0

module Hydra
  module Works
    module WorkBehaviorDecorator
        # OVERRIDE hydra-works v.1.2.0
        # we need the child works to be in the order they're listed in the csv
        def child_works
          ordered_works + member_works
        end
    end
  end
end

::Hydra::Works::WorkBehavior.prepend(Hydra::Works::WorkBehaviorDecorator)
