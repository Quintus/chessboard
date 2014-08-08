Chessboard::App.controllers :administration do

  before do
    env["warden"].authenticate!
    halt 403 unless env["warden"].user.admin?
  end
  
  get :configuration, :map => "/admin/configuration" do
    @configuration = GlobalConfiguration.instance
    render "configuration"
  end

  patch :configuration, :map => "/admin/configuration" do
    @configuration = GlobalConfiguration.instance

    if @configuration.update_attributes(params["global_configuration"])
      flash[:notice] = I18n.t("configuration.updated")
      redirect url(:global_configuration, :configuration)
    else
      render "configuration"
    end
  end

  get :users, :map => "/admin/users" do
    render "users"
  end

  post :users, :map => "/admin/users" do
    user = User.where(:nickname => params["nickname"]).first
    unless user
      flash[:alert] = I18n.t("admin.users.not_found")
      return redirect(url(:administration, :users))
    end

    redirect url(:administration, :user, user.nickname)
  end

  get :user, :map => "/admin/user/:nickname" do
    @user = User.find_by!(:nickname => params["nickname"])
    render "user"
  end

  delete :user, :map => "/admin/user/:nickname" do
    @user = User.find_by!(:nickname => params["nickname"])
    @user.destroy!

    flash[:notice] = I18n.t("admin.users.deleted")
    redirect url(:administration, :users)
  end

end
