class Chessboard::User < Sequel::Model
  one_to_many :posts, :key => :author_id
  many_to_many :tags
  many_to_many :read_posts,    :left_key => :user_id, :right_key => :post_id, :class => :Post, :join_table => :read_posts
  many_to_many :watched_posts, :left_key => :user_id, :right_key => :post_id, :class => :Post, :join_table => :watched_posts

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

  # Like ::guest, but only returns the numeric ID of the Guest user.
  def self.guest_id
    Chessboard::User.where(:email => GUEST_EMAIL).limit(1).get(:id)
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
    deleted_emails.each{|email| Chessboard::Application.logger.info("Deleting #{email}")}
    Chessboard::User.where(:email => deleted_emails).all.each(&:destroy)

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
    Chessboard::Configuration[:subscribe_to_nomail].call(forum.mailinglist, email)
  end

  # Unsubscribe this user from the mailinglist.
  # +forum+ is the Forum instance whose mailinglist the user shall be
  # unsubscribed from.
  def unsubscribe_from_mailinglist(forum)
    Chessboard::Configuration[:unsubscribe_from_ml].call(forum.mailinglist, email)
  end

  # Checks if this user is subscribed to the mailinglist behind
  # +forum+, and if so, returns true, otherwise returns false.
  def subscribed_to_mailinglist?(forum)
    Chessboard::Configuration[:load_ml_users].call(forum.mailinglist).include?(email)
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

  # Returns true if the given post was _not_ read by this user,
  # false otherwise.
  # Inverse of #read?.
  def unread?(post)
    Chessboard::Application::DB[:read_posts].where(:post_id => post.id, :user_id => id).empty?
  end

  # Returns true if the given post was read by this user,
  # false otherwise.
  # Inverse of #unread?.
  def read?(post)
    !unread?(post)
  end

  # Returns the most recent alias name of this user.
  # Returns nil if there is no alias associated with this
  # user (which indicates a bug as any user creation should
  # always add at least one alias).
  #
  # See also #alias_at_time.
  def current_alias
    alias_at_time(Time.now.utc)
  end

  # Return the alias that was in use at the given point in time.
  # Returns nil if there was no alias for this user at the given
  # time.
  #
  # Raises RangeError if the user was not registered at the time
  # requested.
  #
  # See also #current_alias.
  def alias_at_time(time)
    # Force DateTime over to Time, make it UTC
    time = time.to_time if time.respond_to?(:to_time)
    time = time.utc

    if time < created_at
      raise RangeError, "Requested to retrieve an alias from before the user #{id} was registered (#{created_at}, requested was #{time})!"
    end

    Chessboard::Application::DB[:user_aliases]
      .where(:user_id => id)
      .where{created_at <= time}
      .order(Sequel.desc(:created_at))
      .limit(1)
      .get(:name)
  end

  # Add a new alias for this user. You may override the
  # creation time to insert an older alias if you have an
  # old message from this user with a not-yet-used alias
  # that is as of now not used anymore.
  def add_alias(display_name, creation_time = Time.now)
    # Force DateTime over to Time and make it UTC
    creation_time = creation_time.to_time if creation_time.respond_to?(:to_time)
    creation_time = creation_time.dup.utc

    Chessboard::Application::DB[:user_aliases]
      .insert(:user_id => id,
              :name => display_name,
              :created_at => creation_time)
  end

  # Returns all aliases this user ever used as a two-dimensional
  # array of this form:
  #
  #   [[start_time, alias_name], ...]
  #
  #
  # +start_time+ indicates when the user started using this alias,
  # +alias_name+ is the alias as a string.
  #
  # If the user switched back to an earlier used alias, you might get
  # duplicate alias names for different times.
  #
  # The array is sorted in ascending order, i.e. the first alias ever
  # used comes first.
  def all_aliases
    Chessboard::Application::DB[:user_aliases]
      .where(:user_id => id)
      .order(Sequel.asc(:created_at))
      .select_map([:name, :created_at])
  end

  # Move all posts of this user to another user.
  # Note the post's 'used_alias' attribute is left untouched,
  # so the UI will still display the old name next to the post
  # (as it should be with a ML archive).
  def move_all_posts_to_other_user_id!(user_id)
    Chessboard::Application::DB[:posts]
      .where(:author_id => id)
      .update(:author_id => user_id)
  end

  # Returns a Time instance representing the point in time where the
  # registration confirmation token expires.
  def confirmation_expiry_time
    created_at + Chessboard::Configuration[:confirmation_expiry]
  end

  # Returns true if the registration confirmation token has expired,
  # false otherwise.
  def confirmation_token_expired?
    Time.now.utc > confirmation_expiry_time
  end

  # Make this user a watcher of the given post. +post+ may either be an
  # ID or an instance of Chessboard::Post.
  # No subsequent #save needed.
  def watch!(post)
    post = post.id if post.kind_of?(Chessboard::Post)

    Chessboard::Application::DB[:watched_posts].insert(:post_id => post, :user_id => id)
  end

  # Remove this user from the list of watchers of the given post. +post+ may
  # either be an ID or an instance of Chessboard::Post.
  # No subsequent #save needed.
  def unwatch!(post)
    post = post.id if post.kind_of?(Chessboard::Post)

    Chessboard::Application::DB[:watched_posts].where(:post_id => post, :user_id => id).delete
  end

  # Checks if this user watches the given post *or any of its
  # parents*, and if so, returns true, otherwise returns false. +post+
  # may either be an ID or an instance of Chessboard::Post.
  def watches?(post)
    post = post.id if post.kind_of?(Chessboard::Post)

    !Post.where(:id => post)
      .union(post.ancestors_dataset, :all => true)
      .where(:post_id => post, :user_id => id)
      .empty?
  end

  private

  def before_create
    self[:created_at]   ||= Time.now.utc
    self[:title]        ||= Chessboard::Configuration[:default_user_title]

    super
  end

  def before_destroy
    Chessboard::Forum.all.each do |forum|
      if subscribed_to_mailinglist?(forum)
        unsubscribe_from_mailinglist(forum)
      end
    end

    Chessboard::Application::DB[:user_aliases].where(:user_id => id).delete
    Chessboard::Application::DB[:read_posts].where(:user_id => id).delete

    posts.each(&:destroy)

    super
  end

end
