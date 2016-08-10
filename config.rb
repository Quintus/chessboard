# config.rb -- Chessboard configuration file
# This file configures the main aspects of Chessboard. It is
# loaded as Ruby code, but it is kept intentionally simple so
# that understanding it does not require you to know Ruby,
# unless you want to use a very specific configuration.
Chessboard::Configuration.create do |config|

  # This is displayed at large on the top of the website.
  board_title "Chessboard forums"

  # And this a little smaller below it.
  board_subtitle "A test installation of Chessboard."

  # This specifies the SQL database to connect to. Chessboard
  # keeps a little information on its own, which is stored here.
  # Examples are user signatures. Supported database types
  # are PostgreSQL, MySQL, and SQLite version 3.
  database_url "postgres:user@host:password/dbname"
  #database_url "mysql:user@host:password/dbname"
  #database_url "sqlite:///var/dbs/mydatabase.db3"

  # How many threads should be displayed on a page. The higher this
  # value, the more strain is loaded to your CPU and hard disk when
  # viewing the index page of a forum.
  threads_per_page 15

  # Some persons have the annoying habit to send HTML-only email.
  # For these messages, Chessboard invokes the program
  # specified with this option and reads the result from
  # standard input and uses that for the content.
  # A %s in this string will be replaced with the path
  # to a temporary file containig the HTML message (the path
  # is guaranteed to end with ".html").
  # The output of the command is required to be in UTF-8.
  #
  # Set this to nil if you want HTML-only mail to give
  # an error message instead.
  html_formatter "lynx -dump '%s'"
  #html_formatter nil

  # If the forum needs to send important information, this is
  # where that information is send to. (Example: A user reports
  # a post as abuse).
  admin_email "root@localhost"

  # If the forum needs to send an email, it invokes the `sendmail'
  # program. Specify here the path to that program.
  sendmail_path "/sbin/sendmail"

  # Users without a specifically assigned title gain this title.
  default_user_title "Member"

  # How threads are displayed to the user by default. Users
  # not logged in will see the post by this mode only, unless
  # they directly follow another URL. :threads means an email-like
  # threaded view, :topics a forum-typical list of posts.
  default_view_mode :topics

  # If this is set to :file, logs are written to the file
  # given with the log_file parameter. If this is :syslog,
  # messages are sent to syslog on facility specified with log_facility.
  log :file # Or :syslog

  # If log is set to :file, this specifies the file to log to.
  # Ensure Chessboard can write to this file.
  log_file "/tmp/chessboard.log"

  # If log is set to :syslog, this specifies the facility to
  # log to. See syslog(3) for the list of facilities.
  #log_facility :daemon

  ########################################
  # LDAP authentication

  # Set this to true if you want to authenticate users not
  # against a password stored in the database, but against
  # an LDAP server. Enabling this will disable registration!
  ldap false

  # DNS name or IP of your LDAP server.
  #ldap_host "my_host"

  # Port of your LDAP service. This defaults to 389 if not given.
  #ldap_port 389

  # Specify the encryption type of the LDAP service. If not
  # specified, an unencrypted connection will be made.
  # Use :start_tls for StartTLS and :simple_tls for LDAPS.
  #ldap_encryption :start_tls # or :simple_tls for LDAPS

  # In order to authenticate users, Chessboard will try to BIND
  # as the user who wants to authenticate. The DN it tries to
  # bind with is specified by this option, which is actually
  # a pattern of how to build the full DN. %s in this string
  # is replaced by the email address of the user to authenticate.
  # ldap_user_dn "uid=%s,ou=users,dc=example,dc=com"

  ########################################
  # Mailinglist-specific config

  # Chessboard provides premade configuration for the Mlmmj
  # mailinglist management software. Just specify the path
  # to the mailinglist directory.
  use_premade_config "mlmmj"

  # Things are more complicated when you do not use a
  # mailinglist manager for which Chessboard has a premade
  # configuration. Consult the documentation on how to
  # proceed here then.
end
