Fabricator(:personal_post) do
  content { Faker::Lorem.paragraphs.join("\n\n") }
  markup_language{ Post::DEFAULT_MARKUP_LANGUAGE }
  author { User.all.sample }
end
