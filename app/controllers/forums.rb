Chessboard::App.controllers :forums do
  
  # get :index, :map => '/foo/bar' do
  #   session[:foo] = 'bar'
  #   render 'index'
  # end

  # get :sample, :map => '/sample/url', :provides => [:any, :js] do
  #   case content_type
  #     when :js then ...
  #     else ...
  # end

  # get :foo, :with => :id do
  #   'Maps to url '/foo/#{params[:id]}''
  # end

  # get '/example' do
  #   'Hello world!'
  # end
  
  get :index, :map => "/forums" do
    @forum_groups = ForumGroup.order(:name => :asc)
    render "index"
  end

  get :show, :map => "/forums/:id" do
    @forum = Forum.find(params[:id])
    @topics = @forum.topics.joins(:posts).order("posts.updated_at DESC")
    render "show"
  end

end
