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

  patch :user, :map => "/admin/user/:nickname" do
    @user = User.find_by!(:nickname => params["nickname"])

    params["user"]["moderated_forums"] ||= {} # Allow deletion of all moderation rights

    @user.moderated_forums.clear
    params["user"]["moderated_forums"].each_pair do |fid, mods|
      @user.moderated_forums << Forum.find(fid) if mods.to_i == 1
    end

    @user.forced_rank = params["user"]["forced_rank"]
    @user.admin = params["user"]["admin"].to_i == 1

    if @user.save
      flash[:notice] = I18n.t("admin.users.updated")
      redirect url(:administration, :user, @user.nickname)
    else
      render "user"
    end
  end

  delete :user, :map => "/admin/user/:nickname" do
    @user = User.find_by!(:nickname => params["nickname"])
    @user.destroy!

    flash[:notice] = I18n.t("admin.users.deleted")
    redirect url(:administration, :users)
  end

end
