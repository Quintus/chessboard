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
      deliver(:user, :warning_email, @warning.warned_user.email, @warning.warned_user.nickname, @warning.warning_user.nickname, @warning.reason, board_link)
      flash[:notice] = I18n.t("warnings.warned")

      Moderation.create(:moderator => env["warden"].user,
                        :targetted_user => @warning.warned_user,
                        :action => "User warned.")

      redirect url(:warnings, :index)
    else
      render "moderation/warnings/new"
    end
  end

  get :user_index, :map => "/warnings" do
    @warnings = env["warden"].user.received_warnings.order(:created_at => :asc)
    render "warnings/index"
  end

end
