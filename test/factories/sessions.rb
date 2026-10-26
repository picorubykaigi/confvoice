FactoryBot.define do
  factory :session do
    conference
    sequence(:title) { |number| "セッション #{number}" }
    description { "テスト用セッション" }
    speaker_name { "登壇者" }
    room { "Room 1" }
    starts_at { conference.starts_on.in_time_zone.change(hour: 10) }
    ends_at { starts_at + 50.minutes }
    feedback_open { true }
  end
end
