FactoryBot.define do
  factory :app_group_user do
    association :app_group
    association :user
    association :role
  end
end
