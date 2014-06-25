class User < ActiveRecord::Base

  validates :nickname, :presence => true, :uniqueness => true
  validates :email, :presence => true, :format => /\A.*?@.*\Z/
  validates :rank, :presence => true
  validates :encrypted_password, :presence => true

  # Specify a new password.
  def password=(new_password)
    if new_password.to_s.length > 8
      self.encrypted_password = BCrypt::Password.create(new_password)
    else
      raise(ArgumentError, "Password to short!")
    end
  end

  # Process +password+ and compare it with the encrypted password
  # we have in our database. Returns true on success, false otherwise.
  def authenticate(password)
    BCrypt::Password.new(encrypted_password) == password
  end

end
