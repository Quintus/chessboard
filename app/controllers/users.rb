# -*- coding: utf-8 -*-
Chessboard::App.controllers :users do

  before :except => [:new, :create, :confirm] do
    env["warden"].authenticate!
  end

  get :index, :map => "/users" do
    @users = User.order(:nickname => :asc)
    render "users/index"
  end

  get :new, :map => "/users/new" do
    halt 403 unless GlobalConfiguration.instance.registration
    redirect "/" if env["warden"].authenticated? # Already logged in

    @user = User.new
    render "users/new"
  end

  post :create, :map => "/users/new" do
    halt 403 if !GlobalConfiguration.instance.registration && !(env["warden"].authenticated && env["warden"].user.admin?)
    halt 400 if env["warden"].authenticated? # Already logged in
    @user = User.new

    @user.nickname = params["user"]["nickname"]
    @user.email = params["user"]["email"]

    if params["user"]["password"] != params["user"]["password_confirmation"]
      @user.errors.add(:password, I18n.t("errors.user.password_mismatch"))
      return render("users/new")
    end

    @user.password = params["user"]["password"]

    unless call_hook :ctrl_registration, :user => @user, :params => params
      return render("users/new")
    end

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

  get :show, :map => "/users/:name" do
    @user = User.find_by(:nickname => params["name"])
    render "users/show"
  end

  get :edit, :map => "/users/:name/edit" do
    @user = env["warden"].user

    # Can only edit your own user resource
    halt 403 if @user.nickname != params["name"]

    render "users/edit"
  end

  patch :update, :map => "/users/:name" do
    @user = env["warden"].user

    # Can only edit your own user resource
    halt 403 if @user.nickname != params["name"]

    @user.realname   = params["user"]["realname"]
    @user.homepage   = params["user"]["homepage"]
    @user.signature  = params["user"]["signature"]
    @user.location   = params["user"]["location"]
    @user.profession = params["user"]["profession"]
    @user.jabber_id  = params["user"]["jabber_id"]
    @user.pgp_key    = params["user"]["pgp_key"]

    if @user.save
      flash[:notice] = I18n.t("settings.settings_updated")
      redirect url(:users, :edit, @user.nickname)
    else
      render "users/edit"
    end

  end

  get :delete, :map => "/users/:name/delete" do
    @user = env["warden"].user
    halt 403 if @user.nickname != params["name"]

    render "delete"
  end

  delete :user, :map => "/users/:name" do
    @user = env["warden"].user
    halt 403 if @user.nickname != params["name"]

    env["warden"].logout
    @user.destroy!

    flash[:notice] = I18n.t("users.deleted")
    redirect "/"
  end

  get :passwd, :map => "/users/:name/password" do
    @user = env["warden"].user
    halt 403 if @user.nickname != params["name"]

    render "users/password"
  end

  patch :passwd, :map => "/users/:name/password" do
    @user = env["warden"].user
    halt 403 if @user.nickname != params["name"]

    # Can’t be a validation, because at validation time the password
    # is already hashed and hence of unknown length. Therefore this
    # is checked here.
    if params["user"]["password"].length < 8
      @user.errors.add(:password, I18n.t("errors.user.password_too_short"))
      return render("users/password")
    end

    if params["user"]["password"] != params["user"]["password_confirmation"]
      @user.errors.add(:password, I18n.t("errors.user.password_mismatch"))
      return render("users/password")
    end

    @user.password = params["user"]["password"]
    if @user.save
      flash[:notice] = I18n.t("users.password_changed")
      redirect "/"
    else
      return render("users/password")
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

end
