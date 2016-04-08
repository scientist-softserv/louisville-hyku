FactoryGirl.define do
  factory :base_user, class: User do
    sequence(:email) { |_n| "email-#{srand}@test.com" }
    password 'a password'
    password_confirmation 'a password'

    factory :user do
      after(:create) { |user| user.remove_role(:admin) }
    end

    factory :admin do
      after(:create) { |user| user.add_role(:admin) }
    end
  end
end
