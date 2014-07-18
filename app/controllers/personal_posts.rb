Chessboard::App.controllers :personal_posts do
  
  get :new, :map => "/pms/:id/posts/new" do
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
    if PersonalMessage.find_by(:id => params["id"])
      redirect url(:personal_messages, :show, params["id"])
    else
      redirect url(:personal_messages, :index)
    end
  end

end
