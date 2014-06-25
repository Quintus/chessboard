########################################
# Users

user = User.new(nickname: "admin", password: "adminadmin", email: "admin@admin.ad", rank: "Admin")
user.save

########################################
# Forums

4.times{ Fabricate(:forum_group) }
