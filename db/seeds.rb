########################################
# Global configuration

GlobalConfiguration.create

########################################
# Users

admin = User.new(nickname: "admin", password: "adminadmin", email: "admin@admin.ad", admin: true, confirmed: true)
admin.save

guest =  User.new(:nickname => "Guest", :email => "guest@example.invalid", :confirmed => true, :realname => "Unknown User Dummy", :encrypted_password => "Invalid password", :forced_rank => "Guest")
guest.save

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
