Chessboard::App.controllers :users do

  before :except => [:new, :create, :confirm] do
    env["warden"].authenticate!
  end

  get :new, :map => "/users/new" do
    halt 403 unless Chessboard.config.registration
    @user = User.new
    render "users/new"
  end

  post :create, :map => "/users/new" do
    halt 403 if !Chessboard.config.registration && !(env["warden"].authenticated && env["warden"].user.admin?)
    @user = User.new

    @user.nickname = params["user"]["nickname"]
    @user.email = params["user"]["email"]

    if params["user"]["password"] != params["user"]["password_confirmation"]
      @user.errors.add(:password, "Password mismatch.")
      return render("users/new")
    end

    @user.password = params["user"]["password"]

    if @user.save
      tokenstr = RegistrationToken.generate_tokenstr
      token = RegistrationToken.new
      token.tokenstr = tokenstr
      token.user = @user
      token.save

      deliver :user, :registration_email, @user.email, @user.nickname, CGI.escape(Base64.encode64(tokenstr).strip), board_link
      flash[:notice] = I18n.t("users.registration")
      redirect "/"
    else
      render "users/new"
    end
  end

  get :confirm, :map => "/users/:name/confirm" do
    @user = User.find_by(:nickname => params["name"])
    render "users/confirm"
  end

  patch :confirm, :map => "/users/:name/confirm" do
    halt 400 unless params["token"]
    @user = User.find_by(:nickname => params["name"])

    halt 400 if @user.confirmed?
    token = @user.registration_token

    if token.confirm(Base64.decode64(params["token"]))
      flash[:notice] = "Account activated."
      redirect "/"
    else
      flash[:alert] = "Account activation failed. Did the token expire?"
      redirect "/"
    end
  end

  get :show, :map => "/users/:name" do
    @user = User.find_by(:nickname => params["name"])
    render "users/show"
  end

end
