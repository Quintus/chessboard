Warden::Strategies.add(:password) do

  def valid?
    params["nickname"] && params["password"]
  end

  def authenticate!
    user = User.find_by(nickname: params["nickname"])
    if user
      if !user.confirmed?
        fail!("User not confirmed yet.")
        return
      end

      if Ban.matches_any?(user, request)
        fail!("User or IP banned.")
        return
      end

      if user.authenticate(params["password"])
        success!(user)
      else
        fail!("Invalid password.")
      end
    else
      fail!("Invalid user name.")
    end
  end

end
