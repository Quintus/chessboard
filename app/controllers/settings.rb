Chessboard::App.controllers :settings do
  
  before do
    env["warden"].authenticate! unless env["warden"].authenticated?
  end

  get :edit, :map => "/users/:name/settings/main" do
    @user = env["warden"].user
    halt 403 if @user.nickname != params["name"]

    @settings = @user.settings
    render "settings/edit"
  end

  patch :update, :map => "/users/:name/settings" do
    @user = env["warden"].user
    halt 403 if @user.nickname != params["name"]

    @settings = @user.settings

    @settings.hide_status               = params["settings"]["hide_status"]
    @settings.language                  = params["settings"]["language"]
    @settings.preferred_markup_language = params["settings"]["preferred_markup_language"]
    @settings.time_format               = params["settings"]["time_format"]

    if @settings.save
      flash[:notice] = I18n.t("settings.settings_updated")
      redirect "/settings/main"
    else
      render "settings/main"
    end
  end

end
