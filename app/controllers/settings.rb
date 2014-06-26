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
    @settings = env["warden"].user.settings
    render "settings/avatar"
  end

  patch :avatar, :map => "/settings/avatar" do
    @settings = env["warden"].user.settings

    @settings.use_gravatar = params["settings"]["use_gravatar"]

    # Upload file
    # Rack seems to have a maximum file size at at 1 GiB or so
    old_avatar_path = @settings.avatar_path
    @settings.avatar_path = env["warden"].user.id.to_s + File.extname(params["settings"]["avatar"][:filename])
    File.open(Padrino.root("public", "images", "avatars", @settings.avatar_path), "wb") do |f|
      while chunk = params["settings"]["avatar"][:tempfile].read(1024)
        f.write(chunk)
      end
    end

    if @settings.save
      # Delete old avatar (unless already overwritten)
      if !old_avatar_path.blank? && @settings.avatar_path != old_avatar_path
        File.delete(Padrino.root("public", "images", "avatars", old_avatar_path))
      end

      flash[:notice] = "Avatar updated"
      redirect "/settings/avatar"
    else
      # Delete now unused avatar
      File.delete(Padrino.root("public", "images", "avatars", @settings.avatar_path))

      render "settings/avatar"
    end
  end

end
