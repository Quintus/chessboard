Fabricator(:forum) do
  name { "Forum #{Fabricate.sequence(:forum)}" }
  description { Faker::Lorem.sentence }
end
