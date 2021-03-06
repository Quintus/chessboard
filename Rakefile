require "rake"
require "rake/clean"
require "rdoc/task"
require_relative"lib/chessboard"

CLEAN.include("public/attachments/[0-9]*",
              "public/images/avatars/*.gif",
              "/tmp/chessboard-mls")
task :clean => :drop_dbs

task :drop_dbs do
  rm_f FileList["db/*.db3"]
end

desc "Create the tables in the database (call before first use)."
task :setup do
  Chessboard::Application::DB.create_table :users do
    primary_key :id

    String :uid,                :null => false, :unique => true
    String :email,              :null => false, :unique => true
    String :encrypted_password, :null => false
    String :locale,             :default => "en", :null => false
    String :homepage
    String :location
    String :profession
    String :jabber_id
    String :pgp_key
    String :signature
    String :title,              :null => false
    String :display_name,       :null => false
    TrueClass :hide_status,     :default => false, :null => false
    TrueClass :hide_email,      :default => false, :null => false
    TrueClass :auto_watch,      :default => false, :null => false
    TrueClass :administrator,   :default => false, :null => false
    TrueClass :confirmed,       :default => false, :null => false
    String    :confirmation_string
    Integer   :view_mode_ident, :default => Chessboard::User::VIEWMODE2IDENT[:default], :null => false
    DateTime :last_login
    DateTime :created_at, :null => false

    constraint(:email_format){Sequel.like(:email, "%_@_%")}
    constraint(:title_length, Sequel.char_length(:title) > 2)
    constraint(:display_name_length, Sequel.char_length(:title) > 1)
    constraint(:valid_view_mode, :view_mode_ident => Chessboard::User::VIEWMODE2IDENT.values)
    # The following constraint needs an update each time a new locale is added.
    constraint(:supported_locale, :locale => R18n.available_locales.map(&:code))

    constraint(:display_name_format_no_left_angle,  ~Sequel.like(:display_name, "%<%"))
    constraint(:display_name_format_no_right_angle, ~Sequel.like(:display_name, "%>%"))
  end

  Chessboard::Application::DB.create_table :forums do
    primary_key :id

    String   :name,        :null => false, :unique => true
    String   :description, :null => false
    String   :mailinglist, :null => false, :unique => true
    String   :ml_tag
    String   :ml_subscribe_url
    Integer  :ordernum,    :default => 0, :null => false
    DateTime :created_at,  :null => false

    constraint(:name_length, Sequel.char_length(:name) > 2)
    constraint(:description_length, Sequel.char_length(:description) > 2)
    constraint(:mailinglist_length, Sequel.char_length(:mailinglist) > 2)
  end

  Chessboard::Application::DB.create_table :posts do
    primary_key :id
    foreign_key :forum_id, :forums, :null => false
    foreign_key :author_id, :users, :null => false
    foreign_key :parent_id, :posts, :null => true

    String    :title,        :null => false
    String    :content,      :text => true, :null => false
    String    :ip
    String    :message_id
    TrueClass :sticky,       :default => false, :null => false
    TrueClass :announcement, :default => false, :null => false
    TrueClass :was_html_only,:default => false, :null => false
    Integer   :views,        :default => 0, :null => false
    DateTime :created_at,     :null => false
    DateTime :last_post_date, :null => false
    String   :used_alias,     :null => false
    DateTime :edited_at
    String   :edited_msgid

    constraint(:title_length, Sequel.char_length(:title) > 2)
    constraint(:content_length, Sequel.char_length(:content) => 1..100_000)
    constraint(:view_count){views >= 0}
    constraint(:last_post_date_order){last_post_date >= created_at}
    constraint(:used_alias_length, Sequel.char_length(:used_alias) > 1)
    constraint(:used_alias_format_no_left_angle, ~Sequel.like(:used_alias, "%<%"))
    constraint(:used_alias_format_no_right_angle, ~Sequel.like(:used_alias, "%>%"))
  end

  Chessboard::Application::DB.create_table :tags do
    primary_key :id
    String :name, :null => :false, :unique => true
    String :description, :null => false
    String :color, :null => false, :default => "FFFFFF"

    constraint(:name_length, Sequel.char_length(:name) > 2)
    constraint(:description_length, Sequel.char_length(:description) > 2)
    constraint(:color_length, Sequel.char_length(:color) => 6)
  end

  Chessboard::Application::DB.create_join_table :tag_id => :tags, :post_id => :posts

  Chessboard::Application::DB.create_table :attachments do
    primary_key :id
    foreign_key :post_id, :null => false

    String :filename,  :null => false
    String :mime_type, :null => false

    constraint(:filename_length, Sequel.char_length(:filename) > 2)
    constraint(:mime_type_format, Sequel.like(:mime_type, "%_/_%"))
  end

  Chessboard::Application::DB.create_join_table({:post_id => :posts, :user_id => :users},
                                                {:name => :read_posts})
  Chessboard::Application::DB.create_join_table({:post_id => :posts, :user_id => :users},
                                                {:name => :watched_posts})

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
  guest.uid   = Chessboard::User::GUEST_UID
  guest.email = Chessboard::User::GUEST_EMAIL
  guest.title = "Guest"
  guest.reset_password
  guest.confirmed = true
  guest.save

  puts "Creating Admin user"
  admin = Chessboard::User.new
  admin.uid           = query(:name, "Your nickname: ")
  admin.email         = query(:email, "Your email: ")
  admin.change_password(query(:password, "Your password: "))
  admin.administrator = true
  admin.confirmed     = true
  admin.save
end

desc "Print the routing table."
task :routes do
  Chessboard::Application.routes.each_pair do |method, routes|
    next if method == "HEAD"

    routes.each do |route|
      puts "#{method}\t#{route[0].source}"
    end
  end
end

desc "Main maintenance task; run this periodically from Cron."
task :maintenance do
  # Delete expired confirmation tokens
  Chessboard::User
    .where(:confirmed => false)
    .where{created_at < Time.now.utc - Chessboard::Configuration[:confirmation_expiry]}
    .each(&:destroy)

  # Delete IP address info if its store time is over. Note the #to_i call,
  # as that setting might have been changed to nil after some posts were already
  # in the database. To not have their IP address persist in the database, simply
  # convert the nil value the max_ip_store_timespan setting has in that case to
  # 0, which will cause all stored IP addresses to be wiped (nil.to_i == 0).
  Chessboard::Post
    .where{created_at < Time.now.utc - Chessboard::Configuration[:max_ip_store_timespan].to_i}
    .update(:ip => nil)
end

desc "List all users with nickname (uid) and email address."
task :listusers do
  Chessboard::User.each do |user|
    printf("%03d %20s <%s>\n", user.id, user.uid, user.email)
  end
end

desc "Delete a user with a given UID."
task :deluser do
  uid = query(:uid, "UID of the user to delete: ")
  destroy_posts = query(:destroyposts, "Destroy posts? (yes/no) ", "no") == "yes"

  if user = Chessboard::User.first(:uid => uid) # Single = intended
    unless destroy_posts
      user.move_all_posts_to_other_user_id!(Chessboard::User::guest_id)
    end

    user.destroy
  else
    fail "No such user."
  end
end

desc "Fill the database with some example data."
task :seed do
  sh "bundle exec ruby db/seed.rb"
end

RDoc::Task.new do |rt|
  rt.main = "api_readme.rdoc"
  rt.rdoc_files.include("README", "doc/*.rdoc", "lib/**/*.rb")
  rt.generator = "hanna"
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
