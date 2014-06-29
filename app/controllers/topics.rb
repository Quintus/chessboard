Chessboard::App.controllers :topics do
  
  before :except => :show do
    env["warden"].authenticate!
  end

  get :new, :map => "/topics/new" do
    halt 400 unless params["forum"] # query parameter required!

    @topic = Topic.new
    @topic.posts.build(:markup_language => env["warden"].user.settings.preferred_markup_language)
    @forum = Forum.find(params["forum"])
    render "new"
  end

  get :show, :map => "/topics/:id" do
    @topic = Topic.find(params[:id])
    @topic.views += 1
    @topic.users_who_read_this << env["warden"].user if env["warden"].authenticated? && !env["warden"].user.read?(@topic)
    @topic.save

    render "show"
  end

  post :create, :map => "/topics/new" do
    halt 400 unless params["topic"]["forum_id"]

    @topic = Topic.new
    @topic.title = params["topic"]["title"]
    @topic.forum = Forum.find(params["topic"]["forum_id"])
    @topic.author = env["warden"].user

    # Only admins/moderators can enable these
    @topic.sticky = params["topic"]["sticky"] == "1" if env["warden"].user.admin? || env["warden"].user.moderates?(@topic.forum)
    @topic.announcement = params["topic"]["announcement"] == "1" if env["warden"].user.admin?

    initial_post = Post.new(params["topic"]["posts_attributes"]["0"])
    initial_post.author = env["warden"].user
    @topic.posts << initial_post

    if @topic.save
      flash[:notice] = "Topic created"
      redirect url(:topics, :show, @topic.id)
    else
      @forum = Forum.find(params["topic"]["forum_id"])
      render "new"
    end
  end

  patch :lock, :map => "/topics/:id/lock" do
    @topic = Topic.find(params["id"])
    halt 403 unless env["warden"].user.moderates?(@topic.forum)

    @topic.lock
    flash[:notice] = I18n.t("topics.locked")
    redirect url(:topics, :show, @topic.id)
  end

  patch :unlock, :map => "/topics/:id/unlock" do
    @topic = Topic.find(params["id"])
    halt 403 unless env["warden"].user.moderates?(@topic.forum)

    @topic.unlock
    flash[:notice] = I18n.t("topics.unlocked")
    redirect url(:topics, :show, @topic.id)
  end

  get :move, :map => "/topics/:id/move" do
    @topic = Topic.find(params["id"])
    halt 403 unless env["warden"].user.moderates?(@topic.forum)

    render "topics/move"
  end

  patch :move, :map => "/topics/:id/move" do
    @topic = Topic.find(params["id"])
    halt 403 unless env["warden"].user.moderates?(@topic.forum)

    @topic.forum = Forum.find(params["topic"]["forum_id"])

    if @topic.save
      flash[:notice] = I18n.t("topics.moved")
      redirect url(:topics, :show, @topic.id)
    else
      render "topics/move"
    end
  end

end
