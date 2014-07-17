Chessboard::App.controllers :personal_posts do
  
  get :new, :map => "/pms/:id/posts/new" do
  end

  get :edit, :map => "/pms/:pm_id/posts/:id/edit" do
  end

  patch :update, :map => "/pms/:pm_id/posts/:id" do
  end

  delete :destroy, :map => "/pms/:pm_id/posts/:id" do
  end

end
