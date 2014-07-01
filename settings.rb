# -*- coding: utf-8 -*-
#
# This is the chessboard settings file that specifies base
# configuration options that can’t be specified via the web
# interface.

Chessboard.configure do |config|
  # Main title
  config.title = "Chessboard Forum"
  config.subtitle = "Chessboard default forum."

  # This will be used as the domain part of all absolute links to
  # the forum (mainly in emails) and as the domain part of email
  # addresses used by the forum software.
  config.domain = "localhost"

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

  # After this time registration tokens are invalidated.
  config.registration_expiration = 60 * 60 * 24

  # Set to false to disable registration.
  config.registration = true

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

  ########################################
  # Mail configuration

  # Example sendmail configuration
  config.mail = {
    :type => :sendmail,
    #:options => {
    #  :location => "/usr/sbin/sendmail"
    #}
  }

  # Example SMTP configuration
  #config.mail {
  #  :type => :smtp,
  #  :options => {
  #    :address => "mailserver.com",
  #    :port => 25,
  #    :user_name => "user",
  #    :password => "password",
  #    :authentication => :plain, # or :login, or :cram_md5
  #    :enable_starttls_auto => true
  #  }
  #}

end
