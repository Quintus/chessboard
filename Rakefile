require "rake"
require_relative"lib/chessboard"

desc "Set the database up for first use."
task :setup do
  Chessboard::Application::DB.create_table :users do
    String :email, :primary_key => true
    String :encrypted_password, :null => false
    Boolean :hide_status, :default => false
    Boolean :hide_email, :default => false
    Boolean :auto_watch, :default => false
    String :locale, :default => "en_US", :null => false
    String :homepage
    String :display_name, :null => false
    String :location
    String :profession
    String :jabber_id
    String :pgp_key
    String :signature
  end

  # Force reload so that the models are set up correctly.
  sh "rake synchronize_with_ml"
end

desc "Synchronize account data from the mailinglist into Chessboard."
task :synchronize_with_ml do
  Chessboard::User.sync_with_mailinglist!
end

desc "Live console."
task :console do
  ARGV.clear
  include Chessboard
  require "irb"
  IRB.start
end
