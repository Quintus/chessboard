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

  get :edit, :map => "/topics/:topic_id/posts/:id" do
  end

end
