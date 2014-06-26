Chessboard::App.controllers :settings do
  
  before do
    env["warden"].authenticate! unless env["warden"].authenticated?
  end

  get "/settings" do
    redirect "/settings/main"
  end

  get :main, :map => "/settings/main" do
    @settings = env["warden"].user.settings
    render "settings/main"
  end

  patch :main, :map => "/settings/main" do
    @settings = env["warden"].user.settings

    @settings.hide_status               = params["settings"]["hide_status"]
    @settings.language                  = params["settings"]["language"]
    @settings.preferred_markup_language = params["settings"]["preferred_markup_language"]
    @settings.time_format               = params["settings"]["time_format"]

    if @settings.save
      flash[:notice] = "Settings updated."
      redirect "/settings/main"
    else
      render "settings/main"
    end
  end

  get :avatar, :map => "/settings/avatar" do
    render "settings/avatar"
  end

end
