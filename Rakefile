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
