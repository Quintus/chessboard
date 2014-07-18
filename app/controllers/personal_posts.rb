Chessboard::App.controllers :personal_posts do
  
  before do
    env["warden"].authenticate!
  end

  get :new, :map => "/pms/:id/posts/new" do
    @post = PersonalPost.new(:markup_language => env["warden"].user.settings.preferred_markup_language)
    @post.personal_message = PersonalMessage.find(params["id"])
    render "new"
  end

  post :create, :map => "/pms/:id/posts" do
    @post = PersonalPost.new(params["personal_post"])
    @post.personal_message = PersonalMessage.find(params["id"])
    @post.author = env["warden"].user

    if @post.save
      flash[:notice] = I18n.t("posts.created")
      redirect ppost_url(@post)
    else
      render "new"
    end
  end

  get :edit, :map => "/pms/:pm_id/posts/:id/edit" do
  end

  patch :update, :map => "/pms/:pm_id/posts/:id" do
  end

  delete :destroy, :map => "/pms/:pm_id/posts/:id" do
    @post = PersonalPost.find(params["id"])
    halt 403 unless @post.author == env["warden"].user

    @post.destroy!

    flash[:notice] = I18n.t("posts.deleted")

    # PM itself may has been deleted if this was the last post
    if PersonalMessage.find_by(:id => params["pm_id"])
      redirect url(:personal_messages, :show, params["pm_id"])
    else
      redirect url(:personal_messages, :index)
    end
  end

end
