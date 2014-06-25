########################################
# Users

user = User.new(nickname: "admin", password: "adminadmin", email: "admin@admin.ad", rank: "Admin")
user.save

20.times{ Fabricate(:user) }

########################################
# Forums

4.times{ Fabricate(:forum_group) }
