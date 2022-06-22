# frozen_string_literal: true

module Hyrax
  class LanguageAuthorities < QaSelectService
    def initialize
      super('languages')
    end
  end
end
