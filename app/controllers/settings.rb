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

  get :avatar, :map => "/settings/avatar" do
    render "settings/avatar"
  end

end
