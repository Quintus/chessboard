Fabricator(:post) do
  content { Faker::Lorem.paragraphs.join("\n\n") }
  language { "Markdown" }
end
