class Chessboard::User < Sequel::Model
  one_to_many :posts, :key => :author_id
  many_to_many :tags

  # Path below the public/ directory to the directory containing the
  # avatar images.
  AVATAR_SUBPATH = "images/avatars".freeze

  # E-Mail address of the Guest user.
  GUEST_EMAIL = "guest@chessboard.invalid".freeze

  # Possible configuration options for viewing a thread. :default
  # means to defer to the +default_view_mode+ global configuration
  # setting. The values are the integers under which the modes
  # are stored in the database.
  VIEWMODE2IDENT = {
    :default => 0,
    :threads => 1,
    :topics => 2
  }.freeze

  # Invert of VIEWMODE2IDENT.
  IDENT2VIEWMODE = VIEWMODE2IDENT.invert.freeze

  # Returns the user representing "guests". This is a placeholder
  # user not used under normal circumstances, but comes into play
  # if users delete their accounts.
  # The return value is an instance of User with a special, invalid
  # email address assigned to it (GUEST_EMAIL constant).
  def self.guest
    Chessboard::User.where(:email => GUEST_EMAIL).first
  end

  # Synchronise the list of accounts on the forum with the subscribers
  # list of the mailinglist management program. All accounts whose
  # address is not in the mailinglist registers will be deleted, and
  # for each account in the mailinglist registers that is not in
  # Chessboard's database a new account will be created.
  def self.sync_with_mailinglists!
    mailinglists = Chessboard::Configuration.mirrored_mailinglists

    # Get a list of all subscribers of all mailinglists.
    emails = []
    mailinglists.each do |mailinglist|
      Chessboard::Configuration[:load_ml_users].call(mailinglist).each do |subscriber_mail|
        emails << subscriber_mail unless emails.include?(subscriber_mail)
      end
    end

    emails.sort!

    current_registered_emails = Chessboard::User.select_map(:email)

    # Delete all users not in this list
    deleted_emails = current_registered_emails - emails
    Chessboard::User.where(:email => deleted_emails).destroy
    deleted_emails.each{|email| puts "Deleting #{email}"}

    # Do not add users in the ML to the forum. This is done on-the-fly
    # when a message from a new user is encountered (code deduplication).

    # TODO: Sync with LDAP if enabled.
  end

  # Check the given plaintext password against the password
  # stored in the database in hashed form, or try to bind
  # to the LDAP (depending on the configuration). Returns true
  # on success, false otherwise.
  def authenticate(password)
    if Chessboard::Configuration[:ldap]
      ldap = Chessboard::LDAP.new(self[:email], password)
      if ldap.bind
        true
      else
        Chessboard.logger.warn "LDAP authentication failure for user #{self[:email]}: #{ldap.get_operation_result.inspect}"
        false
      end
    else # No LDAP, validate against the database
      BCrypt::Password.new(encrypted_password) == password
    end
  end

  # Set the stored password hash to the hash of +cleartext+.
  def change_password(cleartext)
    self[:encrypted_password] = BCrypt::Password.create(cleartext)
  end

  # Like #change_password, but also calls #save.
  def change_password!(cleartext)
    change_password(cleartext)
    save
  end

  # Reset the stored password to a random value.
  # Returns the new password in cleartext.
  def reset_password
    new_pw = Array.new(12){ ("a".."z").to_a.sample }.join("")
    change_password(new_pw)
    new_pw
  end

  # Like #reset_password, but also calls #save.
  def reset_password!
    new_pw = reset_password
    save
    new_pw
  end

  # Subscribe this user to the nomail version of the mailinglist.
  # +forum+ is the Forum instance whose mailinglist the user shall be
  # subscribed to.
  def subscribe_to_mailinglist(forum)
    Chessboard::Configuration[:subscribe_to_nomail].call(email, forum.mailinglist)
  end

  # Unsubscribe this user from the mailinglist.
  # +forum+ is the Forum instance whose mailinglist the user shall be
  # unsubscribed from.
  def unsubscribe_from_mailinglist(forum)
    Chessboard::Configuration[:unsubscribe_from_ml].call(email, forum.mailinglist)
  end

  # Dataset for all thread starter posts this user made.
  def threads
    posts_dataset.where(:parent_id => nil)
  end

  # Convenience method for getting view_mode_ident via
  # IDENT2VIEWMODE. Never returns :default; if that
  # mode is set, returns the global default.
  def view_mode
    view_mode = IDENT2VIEWMODE[view_mode_ident]
    if view_mode == :default
      Chessboard::Configuration[:default_view_mode]
    else
      view_mode
    end
  end

  # Convenience method for setting view_mode_ident via
  # VIEWMODE2IDENT.
  def view_mode=(val)
    if VIEWMODE2IDENT.has_key?(val)
      self.view_mode_ident = VIEWMODE2IDENT[val]
    else
      raise(ArgumentError, "Invalid view mode #{val}")
    end
  end

  # Returns the absolute path to the avatar image of this use. Does
  # not mean that this has to exist, use #avatar? for that.
  def avatar_path
    File.join(Chessboard::Application.root, "public", AVATAR_SUBPATH, "#{id}.gif")
  end

  # Returns the absolute URL to the avatar image of this user. Does
  # not mean that this has to exist, call #avatar? for that.
  def avatar_url
    "/#{AVATAR_SUBPATH}/#{id}.gif"
  end

  # Checks if this user has an avatar set and returns true if so,
  # returns false otherwise.
  def avatar?
    File.exists?(avatar_path)
  end

  # Convenience shortcut for #administrator.
  def admin?
    administrator
  end

  private

  def before_create
    self[:display_name] ||= self[:email].split("@")[0]
    self[:created_at]   ||= Time.now
    self[:title]        ||= Chessboard::Configuration[:default_user_title]

    super
  end

end
