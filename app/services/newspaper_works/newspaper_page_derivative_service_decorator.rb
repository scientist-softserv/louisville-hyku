# frozen_string_literal: true

# Overrides newspaper_works 1.0.1 to apply derivitive services to all work types

module NewspaperWorks
  module NewspaperPageDerivativeServiceDecorator
    def valid?
      true
    end
  end
end

NewspaperWorks::NewspaperPageDerivativeService.prepend(NewspaperWorks::NewspaperPageDerivativeServiceDecorator)
