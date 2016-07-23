class Chessboard::User < Sequel::Model

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

    # Add all users not in this list
    new_emails = emails - current_registered_emails
    new_emails.each do |email|
      puts "Adding #{email}"
      user = Chessboard::User.new
      user[:email] = email
      user.reset_password
      user.save
    end

    # Since the new email addresses came from the mailinglists,
    # there is no need to subscribe these new users to the mailinglists.
    # They're already there.
  end

  # Check the given plaintext password against the password
  # stored in the database in hashed form, or try to bind
  # to the LDAP (depending on the configuration). Returns true
  # on success, false otherwise.
  def authenticate(password)
    if Chessboard::Configuration.ldap
      ldap = Chessboard::LDAP.new(self[:email], password)
      if ldap.bind
        true
      else
        Chessboard::Application.logger.warn "LDAP authentication failure for user #{self[:email]}: #{ldap.get_operation_result.inspect}"
        false
      end
    else # No LDAP, validate against the database
      BCrypt::Password.new(password) == encrypted_password
    end
  end

  # Set the stored password hash to the hash of +cleartext+.
  def change_password(cleartext)
    self[:encrypted_password] = BCrypt::Password.create(cleartext)
  end

  # Reset the stored password to a random value.
  # Returns the new password in cleartext.
  def reset_password
    new_pw = Array.new(12){ ("a".."z").to_a.sample }
    change_password(new_pw)
    new_pw
  end

  # Subscribe this user to the nomail version of the mailinglist.
  def subscribe_to_nomail
    Chessboard::Configuration[:subscribe_to_nomail].call(email)
  end

  private

  def before_create
    unless self[:display_name]
      self[:display_name] = self[:email].split("@")[0]
    end

    self[:created_at] = Time.now

    super
  end

end
