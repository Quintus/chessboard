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
  # Defining the forums

  # This defines a new forum group. All add_forum directives afterwards
  # refer to this forum group.
  add_forum_group "The Secret Chronicles"

  # This defines a forum named "Discussion" inside the above forum group.
  # It mirrors the (mlmmj, see below) mailinglist at /tmp/mltest. For
  # this mailinglist, it is the catchall forum, so that all mails that
  # do not fit elsewhere will show up in this forum.
  add_forum name: "Discussion",
            mailinglist: "/tmp/mltest",
            description: "Open discussion around playing and using TSC.",
            id: 1,
            catchall: true

  # This defines a forum named "Help", which also mirrors the mlmmj
  # mailinglist at /tmp/mltest. However, since "catchall" is not set,
  # it will only pick up mails which are configured for this forum
  # (by means of an X-Chessboard-Forum email header or the
  # corresponding directive in the mail body).
  add_forum name: "Help",
            mailinglist: "/tmp/mltest",
            description: "Problems with the game or the editor?",
            id: 2

  # Another forum group with another forum in it.
  add_forum_group "User Content"
  add_forum name: "Levels",
            mailinglist: "/tmp/mltest",
            description: "This is the place to show your levels to the public.",
            id: 3

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
