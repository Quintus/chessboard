Chessboard::App.controllers :posts do

  before do
    env["warden"].authenticate!
  end

  get :new, :map => "/topics/:topic_id/posts/new" do
    @post = Post.new(:markup_language => env["warden"].user.settings.preferred_markup_language)
    @topic = Topic.find(params["topic_id"])
    render "posts/new"
  end

  post :create, :map => "/topics/:topic_id/posts/new" do
    halt 400 unless params["post"]

    @post = Post.new(params["post"])
    @post.topic = Topic.find(params["topic_id"])
    @post.author = env["warden"].user

    halt 403 if @post.topic.locked?

    # This hook can prevent saving of the post
    unless call_hook(:ctrl_post_create, :post => @post)
      if request.xhr?
        halt 400
      else
        @topic = @post.topic
        return render("posts/new")
      end
    end

    if request.xhr?
      if @post.save
        hsh = {"post_count" => env["warden"].user.posts.count,
          "post_created" => I18n.l(@post.created_at, :format => :long),
          "post_num" => @post.topic.posts.count,
          "post_link" => url(:topics, :show, @post.topic.id) + "#p#{@post.id}",
          "post_content" => process_markup(@post.content, @post.markup_language)}

        hsh.to_json
      else
        halt 400
      end
    else
      if @post.save
        flash[:notice] = "Post created."
        redirect url(:topics, :show, @post.topic.id) + "#p#{@post.id}"
      else
        @topic = @post.topic
        render "posts/new"
      end
    end
  end

  get :edit, :map => "/topics/:topic_id/posts/:id/edit" do
    @post = Post.find(params["id"])
    halt 403 if @post.topic.locked?
    halt 403 unless @post.can_user_change_this?(env["warden"].user)

    @topic = @post.topic
    render "posts/edit"
  end

  put :update, :map => "/topics/:topic_id/posts/:id" do
    @post = Post.find(params["id"])
    halt 403 if @post.topic.locked?
    halt 403 unless @post.can_user_change_this?(env["warden"].user)

    # This hook can prevent saving of the post
    unless call_hook(:ctrl_post_update, :post => @post)
      @topic = @post.topic
      return render("posts/new")
    end

    if @post.update_attributes(params["post"])
      flash[:notice] = "Posting updated"
      redirect url(:topics, :show, @post.topic.id) + "#p#{@post.id}"
    else
      @topic = @post.topic
      render "posts/edit"
    end
  end

  delete :destroy, :map => "/topics/:topic_id/posts/:id" do
    @post = Post.find(params["id"])
    halt 403 if @post.topic.locked?
    halt 403 unless @post.can_user_change_this?(env["warden"].user)

    forum = @post.topic.forum

    if @post.destroy
      flash[:notice] = "Posting deleted."

      # Destroying the last post of a topic will automatically destroy
      # the topic; we cannot rely on a topic existing here anymore, so
      # redirect to the forum instead.
      redirect url(:forums, :show, forum.id)
    else
      flash[:alert] = "Failed to delete posting."
      rediret url(:topics, :show, @post.topic.id)
    end
  end

end
