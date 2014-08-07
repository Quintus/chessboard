Chessboard::App.controllers :global_configuration do

  before do
    env["warden"].authenticate!
    halt 403 unless env["warden"].user.admin?
  end
  
  get :configuration, :map => "/configuration" do
    @configuration = GlobalConfiguration.instance
    render "configuration"
  end

  patch :configuration, :map => "/configuration" do
    @configuration = GlobalConfiguration.instance

    if @configuration.update_attributes(params["global_configuration"])
      flash[:notice] = I18n.t("configuration.updated")
      redirect url(:global_configuration, :configuration)
    else
      render "configuration"
    end
  end

end
