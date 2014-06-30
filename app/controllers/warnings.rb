Chessboard::App.controllers :warnings do
  
  before do
    env["warden"].authenticate!
  end

  get :index, :map => "/moderation/warnings" do
    halt 403 unless env["warden"].user.privileged?

    render "moderation/warnings/index"
  end

end
