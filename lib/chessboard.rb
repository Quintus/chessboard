require "sinatra/base"
require "sinatra/content_for"
require "sinatra/r18n"
require "kramdown"
require "net/ldap"
require "sequel"
require "bcrypt"
require "mail"
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

      DB = Sequel.connect("sqlite://#{root}/db/development.db3", :loggers => [logger])
    end

    configure :production do
      if Config.log == :syslog
        # Note: Syslog::Logger.new takes a facility since Ruby 2.1.0. Before
        # it was impossible to specify a facility.
        set :logger, Syslog::Logger.new("chessboard", Syslog.const_get("LOG_#{Configuration.log_facility.upcase}"))
      else
        set :logger, Logger.new(Configuration.log_file)
      end

      # The Sequel database instance. No SQL logger when run in production.
      DB = Sequel.connect(Configuration.database_url)
    end

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

      session["user"] = user.id
      redirect "/"
    end

    get "/logout" do
      halt 400 unless logged_in?
      session["user"] = nil
      redirect "/"
    end

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

      @thread_starters = @forum.thread_starters.offset(tpp * (@current_page - 1)).limit(tpp)

      erb :forum
    end

    get "/forums/:forum_id/topics/:id" do
      @root_post = Post[params["id"].to_i]
      @forum     = Forum[params["forum_id"].to_i]
      halt 404 unless @forum
      halt 404 unless @root_post
      halt 400 unless @root_post.forum == @forum

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

  end
end

# Now load the rest of the library
require_relative "chessboard/ldap"
require_relative "chessboard/email_document"
require_relative "chessboard/user"
require_relative "chessboard/forum"
require_relative "chessboard/post"
