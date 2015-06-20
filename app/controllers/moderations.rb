Chessboard::App.controllers :moderations do

  # Require membership for viewing the moderation log.
  # For transparency reasons, not only mods should be
  # be able to see the moderation log, but exposing
  # it to everybody on the web overdoes the thing.
  before do
    env["warden"].authenticate!
  end

  get :index, :map => "/moderations" do
    @moderations = Moderation.order(:created_at => :desc).limit(15)
    render "moderations/index"
  end

end
