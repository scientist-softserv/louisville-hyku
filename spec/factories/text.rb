# frozen_string_literal: true

FactoryBot.define do
  factory :text, class: 'Text' do
    title { ['A Text work'] }
    identifier { ['Text_Work_01'] }
  end
end
