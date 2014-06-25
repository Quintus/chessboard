Fabricator(:post) do
  content { Faker::Lorem.paragraphs.join("\n\n") }
  language { "Markdown" }
  author{ User.all.sample }
end
