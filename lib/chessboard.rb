require "sinatra/base"
require "sinatra/content_for"
require "sinatra/r18n"
require "net/ldap"
require "sequel"
require "bcrypt"
require "logger"
require "syslog"
require "syslog/logger"

# Load configuration as early as possible
require_relative "chessboard/configuration"
require_relative "../config.rb"

# Namespace of this program.
module Chessboard

  # Version number of this program.
  VERSION = "0.1.0".freeze

  # Main Sinatra application class.
  class Application < Sinatra::Base
    register Sinatra::R18n
    helpers Sinatra::ContentFor

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

    get "/forums" do
      @forum_groups = Configuration.forum_groups
      erb :forums
    end

  end
end

# Now load the rest of the library
require_relative "chessboard/ldap"
require_relative "chessboard/user"
