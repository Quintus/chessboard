Chessboard::App.controllers :avatars do

  before do
    env["warden"].authenticate!
  end

  # This method replaces whatever avatar is there, hence PUT not POST.
  put :create, :map => "/users/:name/avatar" do
    @user = env["warden"].user
    halt 403 if @user.nickname != params["name"]

    # Remove old avatar if any
    @user.avatar.destroy if @user.avatar

    @avatar = Avatar.new

    # Upload file
    if @avatar.upload!(@user, params["avatar"]["avatar"])
      # TODO: Force browser to refetch avatar image?
      flash[:notice] = I18n.t("avatars.avatar_updated")
      redirect url(:avatars, :show, @user.nickname)
    else
      render "avatars/show"
    end
  end

  get :show, :map => "/users/:name/avatar" do
    @user = env["warden"].user
    halt 403 if @user.nickname != params["name"]

    @avatar = @user.avatar || Avatar.new
    render "avatars/show"
  end

  delete :destroy, :map => "/users/:name/avatar" do
    @user = env["warden"].user
    halt 403 if @user.nickname != params["name"]

    if @user.avatar
      @user.avatar.destroy
      flash[:notice] = I18n.t("avatars.avatar_deleted")
      redirect url(:avatars, :show, @user.nickname)
    else
      flash[:alert] = I18n.t("avatars.avatar_not_deleted")
      redirect url(:avatars, :show, @user.nickname)
    end
  end

end
