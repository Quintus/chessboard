Chessboard::App.controllers :posts do

  before do
    env["warden"].authenticate!
  end

  get :new, :map => "/topics/:topic_id/posts/new" do
    @post = Post.new
    @topic = Topic.find(params["topic_id"])
    render "posts/new"
  end

  post :create, :map => "/topics/:topic_id/posts/new" do
    @post = Post.new(params["post"])
    @post.topic = Topic.find(params["topic_id"])
    @post.author = env["warden"].user

    if request.xhr?
      raise "TODO"
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

end
