Chessboard::App.controllers :bans do
  
  get :index, :map => "/moderation/bans" do
    @bans = Ban.order(:created_at => :desc)
    render "moderation/bans/index"
  end

  get :new, :map => "/moderation/bans/new" do
    @ban = Ban.new
    render "moderation/bans/new"
  end

  post :create, :map => "/moderation/bans" do
    @ban = Ban.new(params["ban"])

    if @ban.save
      flash[:notice] = I18n.t("bans.created")
      redirect url(:bans, :index)
    else
      render "moderation/bans/new"
    end
  end

  get :edit, :map => "/moderation/bans/:id/edit" do
    @ban = Ban.find(params["id"])
    render "moderation/bans/edit"
  end

  patch :update, :map => "/moderation/bans/:id" do
    @ban = Ban.find(params["id"])

    if @ban.update_attributes(params["ban"])
      flash[:notice] = I18n.t("bans.updated")
      redirect url(:bans, :index)
    else
      render "moderation/bans/edit"
    end
  end

  delete :destroy, :map => "/moderation/bans/:id" do
    @ban = Ban.find(params["id"])
    @ban.destroy

    flash[:notice] = I18n.t("bans.deleted")
    redirect url(:bans, :index)
  end

end
