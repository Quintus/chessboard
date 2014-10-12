########################################
# Global configuration

GlobalConfiguration.create

########################################
# Users

user = User.new(nickname: "user", password: "useruseruser", email: "user@user.us", confirmed: true)
user.save

20.times do
  begin
    Fabricate(:user)
  rescue => e
    $stderr.puts("WARNING: Failed to create user: #{e.class.name}: #{e.message}")
  end
end

########################################
# Forums

4.times{ Fabricate(:forum_group) }

########################################
# Some PMs

5.times{ Fabricate(:personal_message) }
