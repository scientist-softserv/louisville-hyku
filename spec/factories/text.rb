# frozen_string_literal: true

FactoryBot.define do
  factory :text, class: 'Text' do
    title { ['A Text work'] }
    identifier { [Faker::Alphanumeric.unique.alphanumeric.to_s] }
  end
end
