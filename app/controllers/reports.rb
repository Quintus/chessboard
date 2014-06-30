Chessboard::App.controllers :reports do

  before do
    env["warden"].authenticate!
  end

  #before :except => [:new, :create] do
  # moderates?
  #end

  get :index, :map => "/reports" do
    user = env["warden"].user
    halt 403 unless user.privileged?

    # Only show those reports the user moderates the forum for
    @reports = Report.where(:closed => false).order(:created_at => :asc).select{|r| user.moderates?(r.post.topic.forum)}

    render "reports/index"
  end

  get :new, :map => "/reports/new" do
    halt 400 unless params["post_id"]
    @report = Report.new
    @post_id = params["post_id"]

    render "reports/new"
  end

  post :create, :map => "/reports/create" do
    post = Post.find(params["report"]["post"])
    @report = Report.new

    halt 403 if post.topic.locked?

    @report.description = params["report"]["description"]
    @report.post = post
    @report.user = env["warden"].user

    if @report.save
      flash[:notice] = I18n.t("reports.reported")
      redirect url(:topics, :show, post.topic.id) + "#p#{post.id}"
    else
      @post_id = params["report"]["post"]
      render "reports/new"
    end
  end

  get :show, :map => "/reports/:id" do
  end

end
