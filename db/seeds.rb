########################################
# Global configuration

GlobalConfiguration.create

########################################
# Users

user = User.new(nickname: "user", password: "useruseruser", email: "user@user.us", confirmed: true)
user.save

20.times{ Fabricate(:user) }

########################################
# Forums

4.times{ Fabricate(:forum_group) }

########################################
# Some PMs

5.times{ Fabricate(:personal_message) }
