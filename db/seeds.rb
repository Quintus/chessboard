########################################
# Users

user = User.new(nickname: "admin", password: "adminadmin", email: "admin@admin.ad", rank: "Admin")
user.save
user.settings.preferred_markup_language = "Markdown"
user.settings.save

20.times{ Fabricate(:user) }

########################################
# Forums

4.times{ Fabricate(:forum_group) }
