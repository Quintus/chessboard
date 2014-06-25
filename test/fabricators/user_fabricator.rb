Fabricator(:user) do
  nickname { Faker::Internet.user_name }
  realname { Faker::Name.name }
  email { Faker::Internet.email }
  homepage { Faker::Internet.url }
  rank { "New Member" }
end
