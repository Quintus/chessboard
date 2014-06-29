Chessboard::App.controllers :users do
    
  get :show, :map => "/users/:name" do
    @user = User.find_by(:nickname => params["name"])
    render "users/show"
  end

end
