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
  config.domain = "localhost:3000"

  # Default locale
  config.default_locale = :en

  # Name of the emoticons set to use (folder in
  # public/images/emoticons).
  config.emoticons_set = "default"

  # Allowed authentication methods for logging in a user. The default
  # authentication methods are:
  # [:password]
  #   BCrypt-encrypted password. This is the strongest authentication
  #   method available and is recommended and required. New users
  #   that register will always use BCrypt'ed passwords!
  # [:sha1password]
  #   SHA1-hashed password. This is provided for compatibility with
  #   FluxBB. This is much weaker then :password, so only use it
  #   in the transition phase!
  config.authentication_methods = [:password, :sha1password]

  # This option defines (in seconds) how long IP addresses are stored before
  # they are cleared when running the :clear_ips Rake task.
  # Set to -1 to disable IP storing completely.
  # You likely need to adjust this setting to comply with your
  # local data protection laws. Note no clearing is done automatically
  # by default -- you have to run the task from Cron if you want to
  # do that.
  config.ip_save_time = 60 * 60 * 24 * 7

  # How long a user is considered active as per the activity
  # overview after he has taken some action, in seconds.
  # It is recommended to set this to five minutes or higher.
  config.online_duration = 60 * 5

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

  ########################################
  # Plugin configuration

  config.plugins.ForumRulesPlugin = {
    :rules => <<-RULES
<h1>Forum rules</h1>
<ol>
<li>The administrator is always right.</li>
<li>If the administrator is not right, rule 1 automatically applies.</li>
</ol>
    RULES
  }

  config.plugins.ImprintPlugin = {
    :imprint => <<-IMPRINT
<h1>Imprint</h1>
Information as per §5 TMG / §55 RStV:

This forum is run and administered by somone, somewhere.
    IMPRINT
  }

  config.plugins.MailinglistPlugin = {
    :ml_path => "/tmp/ml/archive",
    :forum_id => 2,
    :bracket_marked_ml => true,
    :markup_language => "ML Markup",
    :ml_address => "test-ml@example.invalid"
  }

end
