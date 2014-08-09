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
    @topic.sticky = params["topic"]["sticky"] == "1" if env["warden"].user.moderates?(@topic.forum)
    @topic.announcement = params["topic"]["announcement"] == "1" if env["warden"].user.admin?

    initial_post = Post.new(params["topic"]["posts_attributes"]["0"])
    initial_post.author = env["warden"].user
    @topic.posts << initial_post

    # This hook can prevent saving of the topic
    unless call_hook(:ctrl_topic_create, :topic => @topic, :params => params)
      @forum = Forum.find(params["topic"]["forum_id"])
      return render("topics/new")
    end

    if @topic.save
      call_hook(:ctrl_topic_create_final, :topic => @topic)
      flash[:notice] = "Topic created"
      redirect url(:topics, :show, @topic.id)
    else
      @forum = Forum.find(params["topic"]["forum_id"])
      render "new"
    end
  end

  get :edit, :map => "/topics/:id/edit" do
    @topic = Topic.find(params["id"])
    halt 403 if @topic.locked?

    @forum = @topic.forum
    render "edit"
  end

  patch :update, :map => "/topics/:id" do
    @topic = Topic.find(params["id"])
    halt 403 if @topic.locked?

    user = env["warden"].user
    halt 403 if @topic.author != user && !user.moderates?(@topic.forum)

    @topic.title = params["topic"]["title"]

    # Only admins/moderators can enable these
    @topic.sticky = params["topic"]["sticky"] == "1" if user.moderates?(@topic.forum)
    @topic.announcement = params["topic"]["announcement"] == "1" if user.admin?

    # This hook can prevent saving of the topic
    unless call_hook(:ctrl_topic_update, :topic => @topic, :params => params)
      @forum = @topic.forum
      return render("topics/edit")
    end

    if @topic.save
      flash[:notice] = I18n.t("topics.edited")
      redirect url(:topics, :show, @topic.id)
    else
      @forum = @topic.forum
      render "edit"
    end
  end

  patch :lock, :map => "/topics/:id/lock" do
    @topic = Topic.find(params["id"])
    halt 403 unless env["warden"].user.moderates?(@topic.forum)
    halt 403 if @topic.locked?

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

  patch :watch, :map => "/topics/:id/watch" do
    @topic = Topic.find(params["id"])
    user   = env["warden"].user

    @topic.watchers << user unless @topic.watchers.include?(user)
    flash[:notice] = I18n.t("topics.watched")

    redirect url(:topics, :show, @topic.id)
  end

  patch :unwatch, :map => "/topics/:id/unwatch" do
    @topic = Topic.find(params["id"])
    user   = env["warden"].user

    @topic.watchers.delete(user) if @topic.watchers.include?(user)
    flash[:notice] = I18n.t("topics.unwatched")

    redirect url(:topics, :show, @topic.id)
  end

  get :move, :map => "/topics/:id/move" do
    @topic = Topic.find(params["id"])
    halt 403 unless env["warden"].user.moderates?(@topic.forum)
    halt 403 if @topic.locked?

    render "topics/move"
  end

  patch :move, :map => "/topics/:id/move" do
    @topic = Topic.find(params["id"])
    halt 403 unless env["warden"].user.moderates?(@topic.forum)
    halt 403 if @topic.locked?

    @topic.forum = Forum.find(params["topic"]["forum_id"])

    if @topic.save
      flash[:notice] = I18n.t("topics.moved")
      redirect url(:topics, :show, @topic.id)
    else
      render "topics/move"
    end
  end

  get :merge, :map => "/topics/:id/merge" do
    @topic = Topic.find(params["id"])
    halt 403 unless env["warden"].user.moderates?(@topic.forum)
    halt 403 if @topic.locked?

    render "topics/merge"
  end

  delete :merge, :map => "/topics/:id/merge" do
    @topic = Topic.find(params["id"])
    halt 400 unless params["topic"]["target"] # Target topic required
    halt 403 unless env["warden"].user.moderates?(@topic.forum)
    halt 403 if @topic.locked?

    target_topic = Topic.find(params["topic"]["target"])
    halt 404 unless target_topic

    # Move topics from source topic to target topic
    # (automatically clears source topic).
    target_topic.posts.concat(@topic.posts)

    if target_topic.save
      @topic.delete
      flash[:notice] = I18n.t("topics.merged")
      redirect url(:topics, :show, target_topic.id)
    else
      render "topics/merge"
    end
  end

  get :split, :map => "/topics/:id/split" do
    @topic = Topic.find(params["id"])
    halt 403 if @topic.locked?
    halt 403 unless env["warden"].user.moderates?(@topic.forum)

    render "topics/split"
  end

  patch :split, :map => "/topics/:id/split" do
    @topic = Topic.find(params["id"])
    halt 400 unless params["topic"]["post"]
    halt 403 unless env["warden"].user.moderates?(@topic.forum)
    halt 403 if @topic.locked?

    post = Post.find(params["topic"]["post"])
    posts = @topic.posts.order(:created_at => :asc)
    offset = posts.index(post)

    move_posts = posts.offset(offset)

    new_topic = Topic.new
    new_topic.forum = @topic.forum
    new_topic.title = params["topic"]["title"]
    new_topic.author = move_posts.first.author
    new_topic.save

    new_topic.posts.concat(move_posts) # Removes them from original topic
    new_topic.save
    @topic.save

    flash[:notice] = I18n.t("topics.splitted")
    redirect url(:topics, :show, new_topic.id)
  end

end
