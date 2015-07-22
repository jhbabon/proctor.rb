FactoryGirl.define do
  factory :user do
    sequence(:name) { |n| "user-#{n}" }
    password "secret"
    role "admin"

    trait :hal do
      name "hal"
      password "9000"
      role "admin"
    end

    trait :admin do
      role "admin"
    end

    trait :user do
      role "user"
    end

    trait :guest do
      role "guest"
    end

    trait :batman do
      name "batman"
    end

    trait :flash do
      name "flash"
    end

    trait :green_lantern do
      name "green-lantern"
    end

    trait :robin do
      name "robin"
    end
  end

  factory :team do
    sequence(:name) { |n| "user-#{n}" }

    trait :jla do
      name "jla"
    end

    trait :xmen do
      name "x-men"
    end
  end

  factory :pubkey do
    sequence(:title) { |n| "title-#{n}" }
    key "ssh-rsa AAAAA"
    association :user
  end
end
