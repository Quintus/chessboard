Chessboard::App.controllers :forums do

  get :index, :map => "/forums" do
    @forum_groups = ForumGroup.order(:name => :asc)
    render "index"
  end

  get :show, :map => "/forums/:id" do
    @forum = Forum.find(params[:id])
    @topics = @forum.categorized_topics
    @pagetitle = @forum.name
    render "show"
  end

end
