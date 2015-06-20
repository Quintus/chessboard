Chessboard::App.controllers :administration do

  before do
    env["warden"].authenticate!
    halt 403 unless env["warden"].user.admin?
  end

  ########################################
  # GlobalConfiguration object

  get :configuration, :map => "/admin/configuration" do
    @configuration = GlobalConfiguration.instance
    render "configuration"
  end

  patch :configuration, :map => "/admin/configuration" do
    @configuration = GlobalConfiguration.instance

    if @configuration.update_attributes(params["global_configuration"])
      if call_hook :ctrl_configuration, :configuration => @configuration, :params => params
        flash[:notice] = I18n.t("admin.configuration.updated")
        redirect url(:administration, :configuration)
      else
        render "configuration"
      end
    else
      render "configuration"
    end
  end

  ########################################
  # User administration

  get :index_users, :map => "/admin/users" do
    render "users"
  end

  post :index_users, :map => "/admin/users" do
    user = User.where(:nickname => params["nickname"]).first
    unless user
      flash[:alert] = I18n.t("admin.users.not_found")
      return redirect(url(:administration, :index_users))
    end

    redirect url(:administration, :show_user, user.nickname)
  end

  get :show_user, :map => "/admin/users/:nickname" do
    @user = User.find_by!(:nickname => params["nickname"])
    render "user"
  end

  patch :update_user, :map => "/admin/users/:nickname" do
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
      redirect url(:administration, :show_user, @user.nickname)
    else
      render "user"
    end
  end

  delete :destroy_user, :map => "/admin/users/:nickname" do
    @user = User.find_by!(:nickname => params["nickname"])
    @user.destroy!

    flash[:notice] = I18n.t("admin.users.deleted")
    redirect url(:administration, :users)
  end

  ########################################
  # ForumGroup administration

  get :index_forum_groups, :map => "/admin/forum_groups" do
    @forum_groups = ForumGroup.order(:ordernum => :asc)
    render "administration/forum_groups/index"
  end

  patch :update_forum_groups, :map => "/admin/forum_groups" do
    params["forum_group"]["id"].each_with_index do |id, i|
      group = ForumGroup.find(id)

      group.name     = params["forum_group"]["name"][i]
      group.ordernum = params["forum_group"]["ordernum"][i]

      unless group.save
        flash[:alert] = I18n.t("general.errors_occured")
        return redirect(url(:administration, :index_forum_groups))
      end
    end

    redirect "/admin/forum_groups"
  end

  get :new_forum_group, :map => "/admin/forum_groups/new" do
    @forum_group = ForumGroup.new
    render "administration/forum_groups/new"
  end

  post :create_forum_group, :map => "/admin/forum_groups" do
    @forum_group = ForumGroup.new(params["forum_group"])
    if @forum_group.save
      flash[:notice] = I18n.t("admin.forum_groups.created")
      redirect url(:administration, :index_forum_groups)
    else
      render "administration/forum_groups/new"
    end
  end

  delete :destroy_forum_group, :map => "/admin/forum_groups/:id" do
    @forum_group = ForumGroup.find(params["id"])

    @forum_group.destroy
    flash[:notice] = I18n.t("admin.forum_groups.deleted")
    redirect url(:administration, :index_forum_groups)
  end

  ########################################
  # Forum administration

  get :index_forums, :map => "/admin/forums" do
    @forum_groups = ForumGroup.order(:name => :asc)
    render "administration/forums/index"
  end

  patch :update_forums, :map => "/admin/forums" do
    params["forum"]["id"].each_with_index do |id, i|
      forum = Forum.find(id)

      forum.name        = params["forum"]["name"][i]
      forum.forum_group = ForumGroup.find(params["forum"]["forum_group"][i])
      forum.ordernum    = params["forum"]["ordernum"][i]
      forum.description = params["forum"]["description"][i]

      unless forum.save
        flash[:alert] = I18n.t("general.errors_occured")
        return redirect(url(:administration, :index_forums))
      end
    end

    redirect url(:administration, :index_forums)
  end

  get :new_forum, :map => "/admin/forums/new" do
    @forum = Forum.new
    render "administration/forums/new"
  end

  post :create_forum, :map => "/admin/forums" do
    params["forum"]["forum_group"] = ForumGroup.find(params["forum"]["forum_group"])
    @forum = Forum.new(params["forum"])

    if @forum.save
      flash[:notice] = I18n.t("admin.forums.created")
      redirect url(:administration, :index_forums)
    else
      render "administration/forums/new"
    end
  end

  delete :destroy_forum, :map => "/admin/forums/:id" do
    @forum = Forum.find(params["id"])
    @forum.destroy
    flash[:notice] = I18n.t("admin.forums.deleted")
    redirect url(:administration, :index_forums)
  end

end
