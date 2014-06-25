Fabricator(:forum) do
  name { "Forum #{Fabricate.sequence(:forum)}" }
  description { Faker::Lorem.sentence }
  topics(count: 8)
end
