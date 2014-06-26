Fabricator(:post) do
  content { Faker::Lorem.paragraphs.join("\n\n") }
  markup_language { Post::MARKUP_LANGUAGES.sample }
  author{ User.all.sample }
end
