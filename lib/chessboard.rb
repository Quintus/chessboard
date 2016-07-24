require "sinatra/base"
require "sinatra/content_for"
require "sinatra/r18n"
require "net/ldap"
require "sequel"
require "bcrypt"
require "mail"
require "logger"
require "syslog"
require "syslog/logger"
require "digest/md5"

# Load configuration as early as possible
require_relative "chessboard/configuration"
require_relative "../config.rb"
require_relative "chessboard/helpers"

# Namespace of this program.
module Chessboard

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

      session["user"] = user.email
      redirect "/"
    end

    get "/forums" do
      @forum_groups = Configuration.forum_groups
      erb :forums
    end

    get "/forums/:id" do
      @forum = nil
      catch :found do
        Configuration.forum_groups.values.each do |forums_ary|
          forums_ary.each do |forum|
            if forum[:id] == params["id"].to_i
              @forum = forum
              throw :found
            end
          end
        end
      end

      halt 404 unless @forum

      @threads = MessageThread.get_thread_starters(@forum, Configuration[:threads_per_page])
      @total_pages = 1
      @current_pages = 1

      erb :forum
    end

  end
end

# Now load the rest of the library
require_relative "chessboard/ldap"
require_relative "chessboard/user"
require_relative "chessboard/message_thread"
