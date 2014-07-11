Fabricator(:personal_message) do
  posts(count: 5) # TODO: personal_posts?
  author{ User.all.sample }
  title{ Faker::Lorem.sentence }
end
