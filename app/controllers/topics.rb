Chessboard::App.controllers :topics do
  
  before :except => [:show, :feed] do
    env["warden"].authenticate!
  end

  get :new, :map => "/topics/new" do
    halt 400 unless params["forum"] # query parameter required!

    @topic = Topic.new
    @topic.posts.build(:markup_language => env["warden"].user.settings.preferred_markup_language)
    @forum = Forum.find(params["forum"])
    render "new"
  end

  get :feed, :map => "/topics/feed", :provides => [:atom] do
    content_type "application/atom+xml;charset=utf8"

    @posts = Post.order(:updated_at => :desc).limit(20)
    render "topics/feed", :layout => false
  end

  get :search, :map => "/topics/search" do
    render "topics/search"
  end

  post :search, :map => "/topics/search" do
    # Do not allow nasty people to just retrieve the entire list
    # of all the topics/posts.
    if params["text_query"].blank?
      flash[:alert] = I18n.t("search.text_missing")
      return redirect(url(:topics, :search))
    end

    query = Topic.joins(:posts)

    if !params["author_query"].blank?
      query = query.joins("INNER JOIN users ON posts.author_id = users.id")
    end

    query = query.where("posts.content LIKE ?", "%#{params['text_query']}%")

    if !params["author_query"].blank?
      query = query.where("users.nickname LIKE ?", "%#{params['author_query']}%")
    end

    if !params["startdate_query"].blank?
      query = query.where("posts.created_at >= ?", DateTime.parse(params["startdate_query"]))
    end

    if !params["finaldate_query"].blank?
      query = query.where("posts.created_at <= ?", DateTime.parse(params["finaldate_query"]))
    end

    # As a single topic may match multiple times (i.e. each posts match multiple times),
    # shrink multiple occurences of the same topic down to only one appearance of it
    # (using GROUP BY).
    @topics = query.group("topics.id").order("MAX(posts.created_at) DESC")
    @search_term = params["text_query"]
    render "topics/search_results"
  end

  get :show, :map => "/topics/:id" do
    @topic = Topic.find(params[:id])
    @topic.views += 1
    @topic.users_who_read_this << env["warden"].user if env["warden"].authenticated? && !env["warden"].user.read?(@topic)
    @topic.save

    num_posts = GlobalConfiguration.instance.page_post_num
    page = params["page"].to_i # = 0 if not given
    page = 1 if page < 1 # No negative pages
    page -= 1 # First page is 1

    @posts = @topic.posts.order(:created_at => :asc).offset(num_posts * page).limit(num_posts)
    @null_i = num_posts * page # Number of the first post of this page in the topic
    @total_pages = (@topic.posts.count.to_f / num_posts.to_f).ceil
    @current_page = page + 1

    @pagetitle = @topic.title
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
      if Chessboard.config.attachments_enabled && !params["attachments"].blank?
        params["attachments"].each do |attach_hsh|
          begin
            Attachment.from_upload!(initial_post, attach_hsh["description"], attach_hsh["attachment"])
          rescue => e
            logger.error("Failed to save attachment: #{e.class}: #{e.message}: #{e.backtrace.join('\n\t')}")
            flash[:alert] = I18n.t("posts.failed_attachment", :name => attach_hsh["attachment"][:filename], :error => e.message)
          end
        end
      end

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

  delete :destroy, :map => "/topics/:id" do
    @topic = Topic.find(params["id"])
    halt 403 if @topic.locked?
    halt 403 unless env["warden"].user.moderates?(@topic.forum)

    forum = @topic.forum
    if @topic.destroy
      flash[:notice] = I18n.t("topics.deleted")
      redirect url(:forums, :show, forum.id)
    else
      flash[:alert] = "Failed to delete topic."
      redirect url(:topics, :show, @topic.id)
    end
  end

end
