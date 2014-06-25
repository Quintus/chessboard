Fabricator(:forum_group) do
  name { "Forum Group #{Fabricate.sequence(:forum_group)}" }
  forums(count: 2)
end
