require "rake"
require_relative"lib/chessboard"

desc "Create the tables in the database (call before first use)."
task :setup do
  Chessboard::Application::DB.create_table :users do
    primary_key :id

    String :email,              :null => false, :unique => true
    String :encrypted_password, :null => false
    String :locale,             :default => "en", :null => false
    String :homepage
    String :display_name,       :null => false
    String :location
    String :profession
    String :jabber_id
    String :pgp_key
    String :signature
    String :title,              :null => false
    TrueClass :hide_status,     :default => false
    TrueClass :hide_email,      :default => false
    TrueClass :auto_watch,      :default => false
    TrueClass :always_raw,      :default => false
    TrueClass :administrator,   :default => false
    Integer   :view_mode_ident, :default => Chessboard::User::VIEWMODE2IDENT[:default]
    DateTime :created_at
  end

  Chessboard::Application::DB.create_table :forums do
    primary_key :id

    String   :name,        :null => false
    String   :description, :null => false
    String   :mailinglist, :null => false
    String   :ml_tag
    Integer  :ordernum,    :default => 0
    DateTime :created_at
  end

  Chessboard::Application::DB.create_table :posts do
    primary_key :id
    foreign_key :forum_id, :forums, :null => false
    foreign_key :author_id, :users, :null => false
    foreign_key :parent_id, :posts, :null => true

    String    :title,        :null => false
    String    :content,      :text => true
    String    :ip
    String    :message_id
    TrueClass :sticky,       :default => false
    TrueClass :announcement, :default => false
    TrueClass :was_html_only,:default => false
    Integer   :views,        :default => 0
    DateTime :created_at
  end

  Chessboard::Application::DB.create_table :tags do
    primary_key :id
    String :name, :null => :false
    String :description
    String :color, :null => false, :default => "FFFFFF"
  end

  Chessboard::Application::DB.create_join_table :tag_id => :tags, :post_id => :posts

  Chessboard::Application::DB.create_table :attachments do
    primary_key :id
    foreign_key :post_id, :null => false

    String:filename,   :null => false
    String :mime_type, :null => false
  end

  # The initial data needs to be filled in a separate program instance,
  # because Sequel needs the tables at program startup to properly
  # define the models.
  sh "rake create_minimal_data"
  puts "Done. Start Chessboard with $ rackup -p 3000 and browse to port 3000 on this host to test it."
end

desc "Live console."
task :console do
  ARGV.clear
  include Chessboard
  require "irb"

  DB = Chessboard::Application::DB
  IRB.start
end

# Private task that creates a Guest and an Admin user.
task :create_minimal_data do
  puts "Creating Guest user"
  guest = Chessboard::User.new
  guest.display_name = "Guest"
  guest.email = Chessboard::User::GUEST_EMAIL
  guest.reset_password
  guest.save

  puts "Creating Admin user"
  admin = Chessboard::User.new
  admin.display_name = query(:name, "Your nickname: ")
  admin.email        = query(:email, "Your email: ")
  admin.change_password(query(:password, "Your password: "))
  admin.administrator = true
  admin.save
end

namespace :forums do

  desc "Add a new forum."
  task :add => :check_guest_user do
    name        = query(:name, "Name of the new forum: ")
    description = query(:desc, "One-line description of this forum: ")
    ml          = query(:ml, "Name of the mailinglist to mirror: ")
    ml_tag      = query(:ml_tag, "[mailinglist-tag] to remove from title (optional): ", nil)
    ordernum    = query(:ordernum, "Orderung number for this forum (optional): ", -1).to_i

    f = Chessboard::Forum.new
    f.name = name
    f.description = description
    f.mailinglist = ml
    f.ml_tag = ml_tag if !ml_tag.nil? && !ml_tag.empty?
    f.ordernum = ordernum if ordernum >= 0
    f.save

    puts "Created new forum with ID #{f.id}"
    sh "rake forums:synchronize id=#{f.id}"
  end

  desc "Delete a forum."
  task :del do
    id = query(:id, "ID of the forum to delete: ")
    f = Chessboard::Forum.find(id)

    if query(:force, "Forum {id} is '#{f.name}'. Sure you want to delete it (y/n)?").downcase != "y"
      fail "Aborted by user."
    end

    f.destroy
  end

  desc "Synchronize a forum or all forums with its/their mailinglist(s) (wipes all posts currently in the forum(s)!)."
  task :synchronize do
    id = query(:id, "ID of the forum to synchronize: ")

    if id == "all"
      puts "Synchronizing ALL forums..."
      Chessboard::Forum.sync_with_mailinglists!
    else
      f = Chessboard::Forum.find(id)

      puts "Synchronizing forum #{f.id} (#{f.name})..."
      f.sync_with_mailinglist!
    end
  end
end

########################################
# Helper methods

# If available from the environment, return the environment
# variable specified by +key+. Otherwise, query the user
# to input a value by printing +message+ and reading a line
# from standard input. Returns the input stripped from any
# bordering whitesapce in that case.
def query(key, message, defaultvalue = nil)
  key = key.to_s

  return ENV[key] if ENV[key] && !ENV[key].empty?

  print message
  str = $stdin.gets.strip

  if str.strip.empty?
    if defaultvalue
      puts "Using default value of '#{defaultvalue}'"
      str = defaultvalue.to_s
    else
      fail "No input given"
    end
  end

  str
end
