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

      MiniMagick.logger = logger
      DB = Sequel.connect("sqlite://#{root}/db/development.db3", :loggers => [logger])
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

      tpp = Chessboard::Configuration[:threads_per_page]
      @total_pages = (@forum.thread_starters.count.to_f / tpp.to_f).ceil

      if params["page"].to_i > 0
        @current_page = params["page"].to_i
      else
        @current_page = 1
      end

      @announcements   = Chessboard::Post.announcements
      @stickies        = @forum.stickies
      @thread_starters = @forum
                         .thread_starters
                         .exclude(:id => @announcements.map(:id))
                         .exclude(:id => @stickies.map(:id))
                         .offset(tpp * (@current_page - 1))
                         .limit(tpp)

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
      @user.locale      = params["language"] if R18n.available_locales.map(&:code).include?(params["language"])

      # TODO: Rescue validation error
      @user.save

      # TODO: Delete avatar option
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
require_relative "chessboard/user"
require_relative "chessboard/forum"
require_relative "chessboard/post"
require_relative "chessboard/mailinglist_watcher"
