class RegistrationToken < ActiveRecord::Base

  validates :expiration_date, :presence => true
  validates :encrypted_tokenstr, :presence => true

  belongs_to :user

  before_validation do
    if new_record?
      self.expiration_date = Time.now + GlobalConfiguration.instance.registration_expiration
    end
  end

  def self.generate_tokenstr
    str = Array.new(32){ rand(255).chr }.join("")
  end

  def tokenstr=(tokenstr)
    self.encrypted_tokenstr = BCrypt::Password.create(tokenstr)
  end

  # Mark this token as confirmed.
  def confirm(test_tokenstr)
    return false if expired?

    if BCrypt::Password.new(encrypted_tokenstr) == test_tokenstr
      target_user = user
      target_user.confirmed = true
      target_user.save
      destroy
      true
    else
      false
    end
  end

  # Returns true if this token has already expired.
  def expired?
    Time.now > expiration_date
  end

end
