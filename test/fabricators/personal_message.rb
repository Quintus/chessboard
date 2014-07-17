Fabricator(:personal_message) do
  posts(count: 5, fabricator: :personal_post)
  author{ User.all.sample }
  title{ Faker::Lorem.sentence }
end
