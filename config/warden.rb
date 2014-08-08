require "digest/sha1"

Warden::Strategies.add(:password) do

  def valid?
    params["nickname"] && params["password"]
  end

  def authenticate!
    user = User.find_by(nickname: params["nickname"])
    return unless user
    return unless user.confirmed?
    return(fail!("User or IP banned.")) if Ban.matches_any?(user, request)

    begin
      pw = BCrypt::Password.new(user.encrypted_password)
    rescue BCrypt::Errors::InvalidHash
      return # Not in BCrypt format
    end

    if pw == params["password"]
      success!(user)
    end
  end

end

# This strategy is for importing FluxBB passwords, which are unsalted
# SHA1-hashed passwords.
Warden::Strategies.add(:sha1password) do

  def valid?
    params["nickname"] && params["password"]
  end

  def authenticate!
    user = User.find_by(:nickname => params["nickname"])
    return unless user
    return unless user.confirmed?

    if user.encrypted_password == Digest::SHA1.hexdigest(params["password"])
      success!(user)
    end
  end

end
