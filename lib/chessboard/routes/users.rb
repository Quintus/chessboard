class Chessboard::Application < Sinatra::Base

  get "/users/register" do
    halt 403 if !Chessboard::Configuration[:enable_registration]
    halt 403 if Chessboard::Configuration[:ldap]

    @user = Chessboard::User.new
    erb :register
  end

  post "/users" do
    halt 403 if !Chessboard::Configuration[:enable_registration]
    halt 403 if Chessboard::Configuration[:ldap]

    if Chessboard::Configuration[:forum_rules] && params["forum_rules"] != "1"
      @must_accept_forum_rules = true
      halt 400, erb(:register)
    end

    @user = Chessboard::User.new
    @user.uid = params["uid"]
    @user.email = params["email"]
    @user.change_password(params["password"])
    @user.confirmation_string = generate_registration_token(@user)

    begin
      @user.save
    rescue Sequel::ConstraintViolation
      user_error!
      halt 422, erb(:register)
    end

    send_registration_email(@user)

    message t.users.registration
    redirect "/"
  end

  get "/users/:id/confirm/:confirmstr" do
    @user = Chessboard::User[params["id"].to_i]
    halt 404 unless @user
    halt 403 if @user.confirmed # Already confirmed

    if @user.confirmation_string == params["confirmstr"] &&
       !@user.confirmation_token_expired?

      @user.confirmed = true
      @user.confirmation_string = nil
      @user.save
      message t.users.confirmed
      redirect "/"
    else
      alert t.users.confirm_failed
      redirect "/"
    end
  end

  get "/users/:id" do
    halt 401 unless logged_in?
    @user = Chessboard::User[params["id"].to_i]

    halt 404 unless @user

    erb :user
  end

  # Should be a DELETE method, but browsers don't support that.
  post "/users/:id/delete" do
    halt 403 unless Chessboard::Configuration[:enable_registration]
    halt 403 if Chessboard::Configuration[:ldap]
    halt 401 unless logged_in?
    @user = Chessboard::User[params["id"].to_i]

    halt 404 unless @user
    halt 403 unless @user == logged_in_user

    @user.move_all_posts_to_other_user_id!(Chessboard::User::guest_id)
    @user.destroy

    message t.settings.deleted_account
    session["user"] = nil # log the user out
    redirect "/"
  end

end
