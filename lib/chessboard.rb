require "sinatra/base"
require "net/ldap"
require "sequel"
require "bcrypt"
require "logger"

# Load configuration as early as possible
require_relative "chessboard/configuration"
require_relative "../config.rb"

# Namespace of this program.
module Chessboard

  # Version number of this program.
  VERSION = "0.1.0".freeze

  # Main Sinatra application class.
  class Application < Sinatra::Base
    set :root, File.expand_path(File.join(File.dirname(__FILE__), ".."))

    enable :sessions

    configure :development do
      set :database_url, "sqlite://#{root}/db/development.db3"
      set :database_logger, Logger.new($stdout)
    end

    configure :production do
      set :database_url, Chessboard::Config.database_url
      set :database_logger, logger
    end

    # The Sequel database instance.
    DB = Sequel.connect(database_url, :loggers => [database_logger])
  end
end

# Now load the rest of the library
require_relative "chessboard/ldap"
require_relative "chessboard/user"
