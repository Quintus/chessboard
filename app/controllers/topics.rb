Chessboard::App.controllers :topics do
  
  before :except => :show do
    redirect "/login" unless env["warden"].authenticated?
  end

  get :new, :map => "/topics/new" do
    @topic = Topic.new
    @topic.posts.build(:markup_language => env["warden"].user.preferred_markup_language)
    render "new"
  end

  get :show, :map => "/topics/:id" do
    @topic = Topic.find(params[:id])
    @topic.views += 1
    @topic.save

    render "show"
  end

  post :create, :map => "/topics/new" do
    halt 400 unless params["topic"]["forum_id"]

    @topic = Topic.new
    @topic.title = params["topic"]["title"]
    @topic.forum = Forum.find(params["topic"]["forum_id"])
    @topic.author = env["warden"].user

    initial_post = Post.new(params["topic"]["posts_attributes"]["0"])
    initial_post.author = env["warden"].user
    @topic.posts << initial_post

    if @topic.save
      flash[:notice] = "Topic created"
      redirect url(:topics, :show, @topic.id)
    else
      @forum_id = params["topic"]["forum_id"]
      render "new"
    end
  end

end
