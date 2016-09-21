class Chessboard::User < Sequel::Model
  one_to_many :posts, :key => :author_id
  many_to_many :tags
  many_to_many :read_posts,    :left_key => :user_id, :right_key => :post_id, :class => "Chessboard::Post", :join_table => :read_posts
  many_to_many :watched_posts, :left_key => :user_id, :right_key => :post_id, :class => "Chessboard::Post", :join_table => :watched_posts

  # Path below the public/ directory to the directory containing the
  # avatar images.
  AVATAR_SUBPATH = "images/avatars".freeze

  # E-Mail address of the Guest user.
  GUEST_EMAIL = "guest@chessboard.invalid".freeze

  # The UID of the Guest user. This is the only UID that may not
  # ever be present in the LDAP.
  GUEST_UID = "chessboardguest".freeze

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
  # if users delete their accounts or a mail is received from
  # a user who is susbcribed to a mailinglist, but not registered
  # on the forum.
  #
  # The return value is an instance of User with the UID GUEST_UID.
  def self.guest
    Chessboard::User.where(:uid => GUEST_UID).first
  end

  # Like ::guest, but only returns the numeric ID of the Guest user.
  def self.guest_id
    Chessboard::User.where(:uid => GUEST_UID).limit(1).get(:id)
  end

  # Fetch the User instance corresponding to the given Net::LDAP::Entry
  # instance from the SQL database. If there is no corresponding entry,
  # create it and return that one.
  def self.get_from_ldap_entry!(entry)
    if user = first(:uid => result[Chessboard::Configuration[:ldap_user_uid_attr]]) # Single = intended
      user
    else
      user = Chessboard::User.new
      user.uid = result[Chessboard::Configuration[:ldap_user_uid_attr]]
      user.email = result[Chessboard::Configuration[:ldap_user_email_attr]]
      user.confirmed = true # Confirmation happens in LDAP already
      user.reset_password # Does not matter, will be check against LDAP BIND anyway
      user.save
      user
    end
  end

  # Check the given plaintext password against the password
  # stored in the database in hashed form, or try to bind
  # to the LDAP (depending on the configuration). Returns true
  # on success, false otherwise.
  def authenticate(password)
    if Chessboard::Configuration[:ldap]
      ldap = Chessboard::LDAP.new_user_ldap(self, password)
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
    raise NotImplementedError, "TODO"
  end

  # Returns the DN of this user in the LDAP, using the
  # configuration's +ldap_user_dn+. This method raises
  # a NotImplementedError if LDAP authentication is not
  # enabled.
  def full_ldap_dn
    if Chessboard::Configuration[:ldap]
      sprintf(Chessboard::Configuration[:ldap_user_dn], uid)
    else
      raise NotImplementedError, "#full_ldap_dn is only implemented for LDAP authentication!"
    end
  end

  # Some information needs to be retrieved from the LDAP instead
  # of the DB when LDAP is enabled.
  if Chessboard::Configuration[:ldap]

    # Returns the user's email address as it is stored in the DB.
    # If LDAP auth is enabled, returns what is stored in the LDAP instead.
    def email
      retrieve_ldap_attrs[:email]
    end

    # Returns the user's display name as it is stored in the DB.
    # If LDAP auth is enabled, returns what is stored in the LDAP instead.
    def display_name
      retrieve_ldap_attrs[:name]
    end
  end

  private

  def retrieve_ldap_attrs
    @cached_ldap_attrs ||= {}
    if @cached_ldap_attrs.empty?
      ldap = Chessboard::LDAP.new_app_ldap
      result = ldap.search(:base => full_ldap_dn,
                           :return_result => true,
                           :scope => Net::LDAP::SearchScope_BaseObject,
                           :attributes => [Chessboard::Configuraiton[:ldap_user_email_attr],
                                           Chessboard::Configuration[:ldap_user_name_attr]],
                           :size => 1)

      if result.nil?
        # LDAP error
        raise ldap.get_operation_result.inspect
      else
        if result = result.first
          @cached_ldap_attrs[:email] = result[Chessboard::Configuraiton[:ldap_user_email_attr]]
          @cached_ldap_attrs[:name]  = result[Chessboard::Configuration[:ldap_user_name_attr]]
        else
          # This should never happen for a saved user instance.
          raise "Unexpected condition encountered (LDAP search for #{full_dn} returned empty result). This is a bug."
        end
      end
    end

    @cached_ldap_attrs
  end

  def before_create
    self[:created_at]   ||= Time.now.utc
    self[:title]        ||= Chessboard::Configuration[:default_user_title]
    self[:display_name] ||= self[:uid]

    super
  end

  def after_create
    super

    if Chessboard::Configuration[:create_user_hook]
      localpart, domain = email.split("@")
      cmd = sprintf(Chessboard::Configuration[:create_user_hook],
                    :email => email,
                    :localpart => localpart,
                    :domain => domain)

      Chessboard::Application.logger.info("Executing: #{cmd}")
      system(cmd)
    end
  end

  def before_destroy
    Chessboard::Forum.all.each do |forum|
      if subscribed_to_mailinglist?(forum)
        unsubscribe_from_mailinglist(forum)
      end
    end

    Chessboard::Application::DB[:read_posts].where(:user_id => id).delete

    posts.each(&:destroy)

    super
  end

  def after_destroy
    super

    if Chessboard::Configuration[:delete_user_hook]
      localpart, domain = email.split("@")
      cmd = sprintf(Chessboard::Configuration[:delete_user_hook],
                    :email => email,
                    :localpart => localpart,
                    :domain => domain)

      Chessboard::Application.logger.info("Executing: #{cmd}")
      system(cmd)
    end
  end

end
