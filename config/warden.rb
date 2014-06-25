Warden::Strategies.add(:password) do

  def valid?
    params["nickname"] && params["password"]
  end

  def authenticate!
    user = User.find(nickname: params["nickname"])
    if user
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
