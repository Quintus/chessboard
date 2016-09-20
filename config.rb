# -*- coding: utf-8 -*-
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

  # This should be set to the full URL of the board. It is used
  # when the board needs to generate absolute links, most notably
  # in emails it sends out and in the Atom news feed.
  # This must not end with a slash.
  board_url "http://localhost:3000"

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

  # How many posts should be displayed on a page when viewing a topic.
  # This value has no effect for the thread view, which cannot be
  # paginated due to the way it works.
  posts_per_page 10

  # The total size of all attachments in a post may not be greater
  # than this value, in bytes. This value should be set to a value
  # less than the maximum mail size value your mail server allows
  # to prevent the mailserver from rejecting the email generated
  # by Chessboard. It should be less than the mail server's maximum
  # value to account for the main text of the message. This value
  # only applies to posts created via the web interface, emails
  # that are send directly by a user to the mailinglist will be
  # processed in any case.
  max_total_attachment_size 1048576

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
  # a post as abuse). This address is also shown to the users
  # at various places where they are asked to contact the board
  # administration.
  admin_email "root@localhost"

  # This address is used for the "From:" header in outgoing
  # emails of adminsitrative nature (posts are made under
  # the email of the respective user).
  board_email "chessboard@localhost"

  # If the forum needs to send an email, it invokes the `sendmail'
  # program. Specify here the path to that program.
  sendmail_path "/usr/sbin/sendmail"

  # Users without a specifically assigned title gain this title.
  default_user_title "Member"

  # If you set this to false, then new users cannot sign up on the
  # web UI. It is still possible to subscribe to the mailinglists
  # using the respective mailinglist manager's methods, though.
  enable_registration true

  # Timespan in seconds after which registration tokens expire and
  # thus confirmation attempts will be rejected. Once the token
  # has expired, the associated user account may be deleted at any
  # time by the maintenance cronjob.
  confirmation_expiry 60 * 60 * 24 * 2 # 2 days

  # Timespan in seconds after which the IP address info is wiped from
  # posts. Set to nil to disable storing the IP address.
  max_ip_store_timespan 60 * 60 * 24 * 14 # 2 weeks

  # How threads are displayed to the user by default. Users
  # not logged in will see the post by this mode only, unless
  # they directly follow another URL. :threads means an email-like
  # threaded view, :topics a forum-typical list of posts.
  default_view_mode :threads

  # How to check the mailinglists for new mails. The exact values allowed
  # are dependant on the mail configuration in use, but the premade mlmmj
  # configuration supports :inotify and :poll. The former uses the Linux
  # kernel's inotify subsystem to be notified of changes, the latter
  # searches the mailinglist directory every 30 seconds for new mails.
  # Since :inotify is much more performant, you should use it if
  # it is available.
  monitor_method :inotify

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

  # These forum rules are linked to prominently in the navigation,
  # and the user must accept them on registration. If you don't
  # want forum rules, set this to nil. Note that it is recommended
  # to ask users who sign up directly on the mailinglist to accept
  # the same rules as well.
  forum_rules <<EOF
<h1>Forum Rules</h1>
<p>§1. Do not post illegal content.</p>
<p>§2. Do not post obscene content.</p>
<p>§3. Do not post spam.</p>
<p>§4. You agree all your posts are licensed as <a href="https://creativecommons.org/licenses/by/4.0/">CC-BY 4.0.</a></p>
<p>§5. In case you breach one of the above rules, you may be banned from the forum at any time, permanently.</p>
EOF

  # The "imprint" information gives the contact information of
  # the board administrator. German law requires a full paper
  # address and the name of the individual or organisation in
  # charge of the website. Your local laws may differ. If you
  # do not need this information, set this value to nil.
  imprint <<EOF
<h1>Imprint</h1>
<p>This forum is run and administered by:</p>

<p>
Your Name<br/>
Your Address<br/>
Your E-Mail-Address
</p>
EOF

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
  # a pattern of how to build the full DN. The following
  # % escapes are recognised in this string:
  #
  # %{email}
  #   This is replaced by the full email address of the
  #   authenticating user.
  # %{localpart}
  #   This is replaced by the part before the @ of the
  #   user's email address.
  # %{domain}
  #   This is replaced by the part after the @ of the user's
  #   email address.
  # ldap_user_dn "uid=%{email},ou=users,dc=example,dc=com"

  ########################################
  # Mailinglist-specific config

  # Chessboard provides premade configuration for the Mlmmj
  # mailinglist management software. Just specify the path
  # to the mailinglist directory.
  use_premade_config "Mlmmj"

  # Things are more complicated when you do not use a
  # mailinglist manager for which Chessboard has a premade
  # configuration. Consult the documentation on how to
  # proceed here then.

  ########################################
  # Syntax highlighting heuristic

  use_premade_config "RubyAndCppAndXMLHilit"

end
