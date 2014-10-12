# -*- ruby -*-
require 'bundler/setup'
require 'padrino-core/cli/rake'

PadrinoTasks.use(:database)
PadrinoTasks.use(:activerecord)
PadrinoTasks.init

# Internal task for loading all the padrino stuff.
task :load_cb do
  require_relative "config/boot"
end

desc "Delete all stored IPs that are older than the ip_save_time setting."
task :clear_ips => :load_cb do
  target_date = Time.now - Chessboard.config.ip_save_time
  puts "Clearing all stored IP from before #{target_date}..."
  count = Post.where("updated_at <= ?", target_date).update_all(:ip => nil)
  puts "Cleared #{count} IPs."
end

desc "Basic database setup."
task :initialize => ["ar:schema:load"] do
  # Create Admin user
  User.new(nickname: "admin", password: "adminadmin", email: "admin@admin.ad", admin: true, confirmed: true).save!

  # Create Guest user
  User.new(:id => 9999, :nickname => "Guest", :email => "guest@example.invalid", :confirmed => true, :realname => "Unknown User Dummy", :encrypted_password => "Invalid password", :forced_rank => "Guest").save!

  puts "Initialisation done."
  puts "The administrative user has username 'admin' and password 'adminadmin'."
  puts "Have fun with Chessboard!"
end
