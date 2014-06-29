Fabricator(:user) do
  nickname { Faker::Internet.user_name }
  realname { Faker::Name.name }
  email { Faker::Internet.email }
  homepage { Faker::Internet.url }
  password { Faker::Internet.password(8) }
end
