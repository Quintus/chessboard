Chessboard::App.controllers :topics do
  
  get :show, :map => "/topics/:id" do
    @topic = Topic.find(params[:id])
    render "show"
  end

end
