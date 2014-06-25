Fabricator(:topic) do
  posts(count: 5)
  author{ User.all.sample }
  title{ Faker::Lorem.sentence }
end
