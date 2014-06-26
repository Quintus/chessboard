Fabricator(:user) do
  nickname { Faker::Internet.user_name }
  realname { Faker::Name.name }
  email { Faker::Internet.email }
  homepage { Faker::Internet.url }
  rank { "New Member" }
  password { Faker::Internet.password(8) }
  preferred_markup_language{ Post::MARKUP_LANGUAGES.sample }
end
