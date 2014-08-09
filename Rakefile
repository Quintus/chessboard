# -*- ruby -*-
require 'bundler/setup'
require 'padrino-core/cli/rake'
require_relative "config/boot"

PadrinoTasks.use(:database)
PadrinoTasks.use(:activerecord)
PadrinoTasks.init

desc "Delete all stored IPs that are older than the ip_save_time setting."
task :clear_ips do
  target_date = Time.now - Chessboard.config.ip_save_time
  puts "Clearing all stored IP from before #{target_date}..."
  count = Post.where("updated_at <= ?", target_date).update_all(:ip => nil)
  puts "Cleared #{count} IPs."
end
