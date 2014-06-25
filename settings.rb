# -*- coding: utf-8 -*-
#
# This is the chessboard settings file that specifies base
# configuration options that can’t be specified via the web
# interface.

Chessboard.configure do |config|
  # Main title
  config.title = "Chessboard Forum"
  config.subtitle = "Chessboard default forum."

  # Default locale
  config.default_locale = :en

  ########################################
  # Database configuration

  # Example sqlite3 configuration. "Padrino.root"
  # can be used to refer to the project root directory.
  config.database = {
    :adapter => "sqlite3",
    :database => Padrino.root("db", "chessboard.db")
  }

  # Example postgresql configuration.
  #config.database = {
  #  :adapter => "postgresql",
  #  :host => "localhost",
  #  :username => "you",
  #  :password => "yourpassword",
  #  :database => "chessboard"
  #}

  # Example mysql configuration.
  #config.database = {
  #  :adapter => "mysql2",
  #  :encoding => "utf8",
  #  :host => "localhost",
  #  :username => "you",
  #  :password => "yourpassword",
  #  :database => "chessboard",
  #}
end
