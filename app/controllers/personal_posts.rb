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

    halt 403 unless @post.personal_message.allowed_users.include?(env["warden"].user)

    # This hook can prevent saving
    unless call_hook(:ctrl_pp_create, :post => @post, :params => params)
      return render("new")
    end

    if @post.save
      call_hook(:ctrl_pp_create_final, :post => @post)

      @post.personal_message.allowed_users.each do |user|
        next if user == @post.author # Don't email the author about his own PM
        deliver :personal_messages, :pp_email, user.email, user.nickname, @post.author.nickname, @post.personal_message.title, board_link
      end

      flash[:notice] = I18n.t("posts.created")
      redirect ppost_url(@post)
    else
      render "new"
    end
  end

  get :edit, :map => "/pms/:pm_id/posts/:id/edit" do
    @post = PersonalPost.find(params["id"])
    halt 403 unless @post.author == env["warden"].user
    halt 403 unless @post.personal_message.allowed_users.include?(env["warden"].user) # author may have been removed from allowed users in the meanwhile

    render "edit"
  end

  patch :update, :map => "/pms/:pm_id/posts/:id" do
    @post = PersonalPost.find(params["id"])
    halt 403 unless @post.author == env["warden"].user
    halt 403 unless @post.personal_message.allowed_users.include?(env["warden"].user) # author may have been removed from allowed users in the meanwhile

    # This hook can prevent updating
    unless call_hook(:ctrl_pp_update, :post => @post, :params => params)
      return render("edit")
    end

    if @post.update_attributes(params["personal_post"])
      flash[:notice] = I18n.t("pms.edited_post")
      redirect ppost_url(@post)
    else
      render "edit"
    end
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
