class Chessboard::Application < Sinatra::Base

  get "/forums" do
    @forums = Chessboard::Forum.order(:ordernum)
    erb :forums
  end

  get "/forums/:id" do
    @forum = Chessboard::Forum[params["id"].to_i]
    halt 404 unless @forum

    # First acceptable page is 1.
    @current_page = params["page"].to_i
    @current_page = 1 if @current_page < 1

    # Shortcut
    tpp = Chessboard::Configuration[:threads_per_page]

    ########################################
    # Announcements and sticky posts

    @announcements   = Chessboard::Post.announcements
    @stickies        = @forum.stickies

    ########################################
    # Query the requested thread starters

    # Start with all posts.
    @thread_starters = Chessboard::Post.dataset

    # Modify the query if tagged posts were requested.
    if params["tag"]
      # Narrow down to the those thread starters that have all of the requested
      # tags set by means of SQL Common Table Expressions (CTEs) that each build
      # on top of the preceeding one, filtering it down until all tags have
      # been processed.
      tags = params["tag"].map(&:to_i).sort
      tags.each_with_index do |tag_id, index|
        dataset = index.zero? ? Chessboard::Post : DB[Sequel.identifier("tag#{index - 1}")]

        @thread_starters = @thread_starters.with(
          "tag#{index}",
          dataset
            .join(:posts_tags, :post_id => :id)
            .where(Sequel.qualify("posts_tags", "tag_id") => tag_id))
      end

      # Main select of the CTE. The last CTE will contain only those
      # posts that have all requested tags set.
      @thread_starters = @thread_starters.from("tag#{tags.length - 1}")
    end

    # Exclude announcements and stickies.
    @thread_starters = @thread_starters
                       .exclude(:id => @announcements.map(:id))
                       .exclude(:id => @stickies.map(:id))

    # Limit to posts from this forum.
    @thread_starters = @thread_starters.where(:forum_id => @forum.id)

    # Limit to the actual thread starters, i.e. those posts that
    # do not have a parent ID set.
    @thread_starters = @thread_starters.where(:parent_id => nil)

    # Order the result so that the thread that has the most recent reply
    # comes first.
    @thread_starters = @thread_starters.order(Sequel.desc(:last_post_date))

    # Before honouring pagination, count the total amount of posts matching
    # all criteria. This is required for the pagination menu.
    @total_pages = (@thread_starters.count.to_f / tpp.to_f).ceil

    # Now honour the current pagination.
    @thread_starters = @thread_starters
                       .offset(tpp * (@current_page - 1))
                       .limit(tpp)

    # Go!
    @thread_starters = @thread_starters.all

    erb :forum
  end

  get "/forums/:forum_id/topics/:id" do
    @root_post = Chessboard::Post[params["id"].to_i]
    @forum     = Chessboard::Forum[params["forum_id"].to_i]
    halt 404 unless @forum
    halt 404 unless @root_post
    halt 400 unless @root_post.forum == @forum

    ppp = Chessboard::Configuration[:posts_per_page]
    @total_pages = ((1 + @root_post.all_replies.count.to_f) / ppp.to_f).ceil # +1 for the root post

    if params["page"].to_i > 0
      @current_page = params["page"].to_i
    else
      @current_page = 1
    end

    # On the first page, the root post is displayed; it is not part
    # of "all_replies", hence this must be treated specifically by
    # only fetching ppp-1 replies to get the exact number of posts
    # requested on a page. For the the following pages this means
    # that the offset must be calculated from where it was left off
    # (-1).
    if @current_page == 1
      @posts = [@root_post]
      @posts += @root_post.all_replies.limit(ppp - 1).to_a
    else
      @posts = @root_post
               .all_replies
               .offset(ppp * (@current_page - 1) - 1)
               .limit(ppp)
    end

    erb :topic
  end

  get "/forums/:forum_id/threads/:id" do
    @root_post = Chessboard::Post[params["id"].to_i]
    @forum     = Chessboard::Forum[params["forum_id"].to_i]
    halt 404 unless @forum
    halt 404 unless @root_post
    halt 400 unless @root_post.forum == @forum

    erb :thread
  end

end
