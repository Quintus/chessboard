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

  # Normal time format (see date(1)). Empty string means
  # a special format using "a minute ago" and such.
  # This format is used to disply times to unauthenticated
  # users.
  config.normal_time_format = ""

  # Maximum width/height for avatars in pixels.
  config.maximum_avatar_dimension = 80

  # Name of the emoticons set to use (folder in
  # public/images/emoticons).
  config.emoticons_set = "default"

  # After this time warnings expire and are auto-deleted
  # on the user’s next login. Set to 0 to make warnings
  # permanent.
  config.warning_expiration = 60 * 60 * 24 * 365

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
