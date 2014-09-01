Chessboard::App.controllers :forums do

  get :index, :map => "/forums" do
    @forum_groups = ForumGroup.order(:name => :asc)
    render "index"
  end

  get :show, :map => "/forums/:id" do
    @forum = Forum.find(params[:id])

    num_topics = GlobalConfiguration.instance.page_topic_num
    page = params["page"].to_i # = 0 if not given
    page = 1 if page < 1 # No negative pages
    page -= 1 # First page is 1

    @topics = @forum.categorized_topics(num_topics * page, num_topics)
    @null_i = num_topics * page # Number of this page in the forum
    @total_pages = (@forum.topics.count.to_f / num_topics.to_f).ceil
    @current_page = page + 1

    @pagetitle = @forum.name
    render "show"
  end

end
