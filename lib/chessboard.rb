require "sinatra/base"
require "sinatra/content_for"
require "sinatra/r18n"
require "kramdown"
require "net/ldap"
require "sequel"
require "bcrypt"
require "mail"
require "mini_magick"
require "rb-inotify"
require "logger"
require "syslog"
require "syslog/logger"
require "digest/md5"
require "cgi"

# Load configuration as early as possible
require_relative "chessboard/configuration"
require_relative "../config.rb"
require_relative "chessboard/helpers"

# Namespace of this program.
module Chessboard

  # Convenience method for calling Chessboard::Application.logger.
  def self.logger
    Chessboard::Application.logger
  end

  # Version number of this program.
  VERSION = "0.1.0".freeze

  # Main Sinatra application class.
  class Application < Sinatra::Base
    register Sinatra::R18n
    helpers Sinatra::ContentFor
    helpers Chessboard::Helpers

    set :root, File.expand_path(File.join(File.dirname(__FILE__), ".."))

    enable :sessions

    configure :development do
      set :logger, Logger.new($stdout)

      # Always use the same session secret in development so one
      # doesn't have to log in all the time when restarting the server.
      set :session_secret, "xu6yiechiG8cuuy6Heiv"

      MiniMagick.logger = logger
      DB = Sequel.connect("sqlite://#{root}/db/development.db3", :loggers => [logger])

      # In development deliver mails to mailcatcher.
      Mail.defaults do
        delivery_method :smtp, :address => "localhost", :port => 1025
      end
    end

    configure :production do
      if Configuration[:log] == :syslog
        # Note: Syslog::Logger.new takes a facility since Ruby 2.1.0. Before
        # it was impossible to specify a facility.
        set :logger, Syslog::Logger.new("chessboard", Syslog.const_get("LOG_#{Configuration[:log_facility].upcase}"))
      else
        set :logger, Logger.new(Configuration[:log_file])
      end

      # The Sequel database instance. No SQL logger when run in production.
      DB = Sequel.connect(Configuration[:database_url])

      # In production deliver mails via sendmail.
      Mail.defaults do
        delivery_method :sendmail, :location => Chessboard::Configuration[:sendmail_path]
      end
    end

    ########################################
    # General

    get "/" do
      redirect "/forums"
    end

    get "/login" do
      erb :login
    end

    post "/login" do
      user = User.first(:email => params["email"])
      halt 400 unless user
      halt 400 unless user.authenticate(params["password"])

      message t.general.logged_in_successfully
      session["user"] = user.id
      redirect "/"
    end

    get "/logout" do
      halt 400 unless logged_in?
      session["user"] = nil
      redirect "/"
    end

    ########################################
    # Forums

    get "/forums" do
      @forums = Forum.order(:ordernum)
      erb :forums
    end

    get "/forums/:id" do
      @forum = Forum[params["id"].to_i]
      halt 404 unless @forum

      # First acceptable page is 1.
      @current_page = params["page"].to_i
      @current_page = 1 if @current_page < 1

      # Shortcut
      tpp = Chessboard::Configuration[:threads_per_page]

      ########################################
      # Announcements and sticky posts

      @announcements   = Chessboard::Post.announcements
      @stickies        = @forum.stickies

      ########################################
      # Query the requested thread starters

      # Start with all posts.
      @thread_starters = Post.dataset

      # Modify the query if tagged posts were requested.
      if params["tag"]
        # Narrow down to the those thread starters that have all of the requested
        # tags set by means of SQL Common Table Expressions (CTEs) that each build
        # on top of the preceeding one, filtering it down until all tags have
        # been processed.
        tags = params["tag"].map(&:to_i).sort
        tags.each_with_index do |tag_id, index|
          dataset = index.zero? ? Post : DB[Sequel.identifier("tag#{index - 1}")]

          @thread_starters = @thread_starters.with(
            "tag#{index}",
            dataset
              .join(:posts_tags, :post_id => :id)
              .where(Sequel.qualify("posts_tags", "tag_id") => tag_id))
        end

        # Main select of the CTE. The last CTE will contain only those
        # posts that have all requested tags set.
        @thread_starters = @thread_starters.from("tag#{tags.length - 1}")
      end

      # Exclude announcements and stickies.
      @thread_starters = @thread_starters
                         .exclude(:id => @announcements.map(:id))
                         .exclude(:id => @stickies.map(:id))

      # Limit to posts from this forum.
      @thread_starters = @thread_starters.where(:forum_id => @forum.id)

      # Limit to the actual thread starters, i.e. those posts that
      # do not have a parent ID set.
      @thread_starters = @thread_starters.where(:parent_id => nil)

      # Order the result so that the most recent post comes first.
      @thread_starters = @thread_starters.order(Sequel.desc(:created_at))

      # Before honouring pagination, count the total amount of posts matching
      # all criteria. This is required for the pagination menu.
      @total_pages = (@thread_starters.count.to_f / tpp.to_f).ceil

      # Now honour the current pagination.
      @thread_starters = @thread_starters
                         .offset(tpp * (@current_page - 1))
                         .limit(tpp)

      # Go!
      @thread_starters = @thread_starters.all

      erb :forum
    end

    get "/forums/:forum_id/topics/:id" do
      @root_post = Post[params["id"].to_i]
      @forum     = Forum[params["forum_id"].to_i]
      halt 404 unless @forum
      halt 404 unless @root_post
      halt 400 unless @root_post.forum == @forum

      ppp = Chessboard::Configuration[:posts_per_page]
      @total_pages = ((1 + @root_post.all_replies.count.to_f) / ppp.to_f).ceil # +1 for the root post

      if params["page"].to_i > 0
        @current_page = params["page"].to_i
      else
        @current_page = 1
      end

      # On the first page, the root post is displayed; it is not part
      # of "all_replies", hence this must be treated specifically by
      # only fetching ppp-1 replies to get the exact number of posts
      # requested on a page. For the the following pages this means
      # that the offset must be calculated from where it was left off
      # (-1).
      if @current_page == 1
        @posts = [@root_post]
        @posts += @root_post.all_replies.limit(ppp - 1).to_a
      else
        @posts = @root_post
                 .all_replies
                 .offset(ppp * (@current_page - 1) - 1)
                 .limit(ppp)
      end

      erb :topic
    end

    get "/forums/:forum_id/threads/:id" do
      @root_post = Post[params["id"].to_i]
      @forum     = Forum[params["forum_id"].to_i]
      halt 404 unless @forum
      halt 404 unless @root_post
      halt 400 unless @root_post.forum == @forum

      erb :thread
    end

    get "/forums/:forum_id/posts/:id/announce" do
      halt 403 unless logged_in? && logged_in_user.admin?
      @post = Post[params["id"].to_i]
      @forum = Forum[params["forum_id"].to_i]

      halt 404 unless @post
      halt 404 unless @forum
      halt 400 unless @post.forum == @forum

      @post.announcement = true
      @post.save

      message t.posts.marked_as_announcement
      redirect "/forums/#{@forum.id}"
    end

    get "/forums/:forum_id/posts/:id/unannounce" do
      halt 403 unless logged_in? && logged_in_user.admin?
      @post = Post[params["id"].to_i]
      @forum = Forum[params["forum_id"].to_i]

      halt 404 unless @post
      halt 404 unless @forum
      halt 400 unless @post.forum == @forum

      @post.announcement = false
      @post.save

      message t.posts.unmarked_as_announcement
      redirect "/forums/#{@forum.id}"
    end

    get "/forums/:forum_id/posts/:id/stick" do
      halt 403 unless logged_in? && logged_in_user.admin?
      @post = Post[params["id"].to_i]
      @forum = Forum[params["forum_id"].to_i]

      halt 404 unless @post
      halt 404 unless @forum
      halt 400 unless @post.forum == @forum

      @post.sticky = true
      @post.save

      message t.posts.marked_as_sticky
      redirect "/forums/#{@forum.id}"
    end

    get "/forums/:forum_id/posts/:id/unstick" do
      halt 403 unless logged_in? && logged_in_user.admin?
      @post = Post[params["id"].to_i]
      @forum = Forum[params["forum_id"].to_i]

      halt 404 unless @post
      halt 404 unless @forum
      halt 400 unless @post.forum == @forum

      @post.sticky = false
      @post.save

      message t.posts.unmarked_as_sticky
      redirect "/forums/#{@forum.id}"
    end

    get "/forums/:forum_id/posts/:id/reply" do
      halt 403 unless logged_in?

      @forum = Forum[params["forum_id"].to_i]
      @post  = Post[params["id"].to_i]

      halt 404 unless @post
      halt 404 unless @forum
      halt 400 unless @post.forum == @forum

      @suggested_title = @post.title
      @suggested_title = "Re: #{@suggested_title}" unless @suggested_title =~ /^Re:/i
      @tags = Tag.order(Sequel.asc(:name))

      erb :reply
    end

    post "/forums/:forum_id/posts/:id/reply" do
      halt 403 unless logged_in?

      @forum = Forum[params["forum_id"].to_i]
      @parent_post = Post[params["id"].to_i]

      halt 404 unless @parent_post
      halt 404 unless @forum

      @post = Post.new
      @post.content = params["content"]
      @post.title   = params["title"]
      @post.ip      = request.ip
      @post.forum   = @forum
      @post.author  = logged_in_user
      @post.parent  = @parent_post

      # Ensure the attachments' total size does not exceed what is allowed
      if params["attachments"]
        max   = Chessboard::Configuration[:max_total_attachment_size]
        total = params["attachments"].reduce(0){|sum, hsh| sum + hsh[:tempfile].size}
        if total > max
          @attachment_error = t.posts.attachments_too_large(
            readable_bytesize(total),
            readable_bytesize(max))
          halt 413, erb(:reply)
        end
      end

      @tags = Tag.where(:id => params["tags"].keys.map(&:to_i))

      message_id = @post.send_to_mailinglist(@tags, params["attachments"] || [])

      # Give the email infrastructure opportunity to deliver the email.
      # The mailinglist monitor creates a post with the message ID set
      # to the ID generated in Post#send_to_mailinglist, hence this
      # can be used to dig out the created Post instance below.
      # Message IDs are usually unique, the rare duplicates can
      # be ignored.
      sleep 3

      message t.posts.created
      redirect post_url(Post.where(:message_id => message_id).first)
    end

    ########################################
    # Administration

    get "/admin" do
      halt 400 unless logged_in?
      halt 400 unless logged_in_user.admin?

      erb :admin
    end

    get "/admin/tags" do
      halt 400 unless logged_in?
      halt 400 unless logged_in_user.admin?

      @tags = Tag.order(Sequel.asc(:name))
      erb :admin_tags
    end

    post "/admin/tags" do
      halt 400 unless logged_in?
      halt 400 unless logged_in_user.admin?

      @tag = Tag.new
      @tag.name = params["name"]
      @tag.description = params["description"]
      @tag.color = params["color"]

      @tag.save

      message t.admin.tag_created
      redirect "/admin/tags"
    end

    get "/admin/tags/new" do
      halt 400 unless logged_in?
      halt 400 unless logged_in_user.admin?

      @tag = Tag.new
      erb :admin_tags_edit
    end

    get "/admin/tags/:id/edit" do
      halt 400 unless logged_in?
      halt 400 unless logged_in_user.admin?

      @tag = Tag[params["id"].to_i]
      halt 404 unless @tag

      erb :admin_tags_edit
    end

    # Actually this should be patch /admin/tags/:id,
    # but browsers cannot do other methods than GET
    # and POST in HTML forms.
    post "/admin/tags/:id/edit" do
      halt 400 unless logged_in?
      halt 400 unless logged_in_user.admin?

      @tag = Tag[params["id"].to_i]
      halt 404 unless @tag

      @tag.name = params["name"]
      @tag.description = params["description"]
      @tag.color = params["color"]

      @tag.save

      message t.admin.tag_updated
      redirect "/admin/tags"
    end

    delete "/admin/tags/:id" do
      halt 400 unless request.xhr?
      halt 400 unless logged_in?
      halt 400 unless logged_in_user.admin?

      @tag = Tag[params["id"].to_i]
      halt 404 unless @tag

      @tag.destroy

      200
    end

    get "/admin/forums" do
      halt 400 unless logged_in?
      halt 400 unless logged_in_user.admin?

      @forums = Forum.order(Sequel.asc(:ordernum)).all
      erb :admin_forums
    end

    delete "/admin/forums/:id" do
      halt 400 unless request.xhr?
      halt 400 unless logged_in?
      halt 400 unless logged_in_user.admin?

      @forum = Tag[params["id"].to_i]
      halt 404 unless @forum

      @forum.destroy

      200
    end


    ########################################
    # Misc

    get "/settings" do
      halt 400 unless logged_in?

      @user = logged_in_user
      erb :settings
    end

    post "/settings" do
      halt 400 unless logged_in?

      @user = logged_in_user

      @user.hide_status = params["hide_status"] == "1"
      @user.hide_email  = params["hide_email"]  == "1"
      @user.auto_watch  = params["auto_watch"]  == "1"
      @user.always_raw  = params["always_raw"]  == "1"
      @user.locale      = params["language"] if R18n.available_locales.map(&:code).include?(params["language"])

      # TODO: Rescue validation error
      @user.save

      if params["avatar"] && !params["delete_avatar"]
        begin
          image = MiniMagick::Image.open(params["avatar"][:tempfile].path)
          image.resize("80x80") if image.width > 80 || image.height > 80
          image.format "gif"
          image.write @user.avatar_path
        rescue => e
          alert t.settings.avatar_upload_failed
          logger.error("#{e.class}: #{e.message}: #{e.backtrace.join("\n\t")}")
        end
      elsif params["delete_avatar"]
        File.delete(@user.avatar_path) if File.file?(@user.avatar_path)
      end

      message t.settings.updated
      redirect "/settings"
    end

  end
end

# Now load the rest of the library
require_relative "chessboard/ldap"
require_relative "chessboard/email_document"
require_relative "chessboard/raw_document"
require_relative "chessboard/user"
require_relative "chessboard/forum"
require_relative "chessboard/post"
require_relative "chessboard/tag"
require_relative "chessboard/attachment"
require_relative "chessboard/mailinglist_watcher"
