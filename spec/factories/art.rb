# frozen_string_literal: true

FactoryBot.define do
  factory :art, class: 'Art' do
    title { ['A work of art'] }
    identifier { [Faker::Alphanumeric.unique.alphanumeric.to_s] }
  end
end
