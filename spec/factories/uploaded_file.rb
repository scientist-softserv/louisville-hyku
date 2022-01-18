# frozen_string_literal: true

FactoryBot.define do
  factory :uploaded_file, class: Hyrax::UploadedFile do
    user_id { user }
  end
end
