Chessboard::App.controllers :warnings do
  
  before do
    env["warden"].authenticate!
  end

  get :index, :map => "/moderation/warnings" do
    halt 403 unless env["warden"].user.privileged?

    # Give 10 users with most warnings
    @top_10_users = User.joins(:received_warnings).group("users.id").order("count(warnings.id) DESC").limit(10)

    render "moderation/warnings/index"
  end

  get :new, :map => "/moderation/warnings/new" do
    halt 403 unless env["warden"].user.privileged?

    @warning = Warning.new
    render "moderation/warnings/new"
  end

  post :create, :map => "/moderation/warnings" do
    halt 403 unless env["warden"].user.privileged?

    @warning = Warning.new
    @warning.warned_user = User.find_by(:nickname => params["warning"]["nickname"])
    @warning.reason = params["warning"]["reason"]
    @warning.warning_user = env["warden"].user

    if @warning.save
      flash[:notice] = I18n.t("warnings.warned")
      redirect url(:warnings, :index)
    else
      render "moderation/warnings/new"
    end
  end

end
