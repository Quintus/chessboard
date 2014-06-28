########################################
# Users

user = User.new(nickname: "admin", password: "adminadmin", email: "admin@admin.ad", rank: "Admin", admin: true)
user.save
user.settings.preferred_markup_language = "Markdown"
user.settings.save

user = User.new(nickname: "user", password: "useruseruser", email: "user@user.us")
user.save

20.times{ Fabricate(:user) }

########################################
# Forums

4.times{ Fabricate(:forum_group) }
