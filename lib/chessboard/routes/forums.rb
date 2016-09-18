# coding: utf-8
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

    @announcements   = Chessboard::Post.announcements.all
    @stickies        = @forum.stickies.all

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
                       .exclude(:id => @announcements.map(&:id))
                       .exclude(:id => @stickies.map(&:id))

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
    @thread_starters = @thread_starters.eager(:forum).all

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
      @posts = Chessboard::Post.where(:id => @root_post.id).union(@root_post.all_replies.limit(ppp - 1), :all => true)
      # UNION ALL is possible because there cannot be duplicates
      # in the result logically; the root post is never one of
      # its own replies.
    else
      @posts = @root_post
               .all_replies
               .offset(ppp * (@current_page - 1) - 1)
               .limit(ppp)
    end

    @posts = @posts.all # execute query

    # TODO: This currently loads ALL posts in this thread, which is
    # unperformant ands voids the efforts the above query carefully
    # makes...
    @thread_info = construct_thread_info(@root_post, logged_in_user)

    if logged_in?
      mark_posts_as_read(@posts.map(&:id))
    end

    @root_post.update(:views => @root_post.views + 1)

    erb :topic
  end

  get "/forums/:forum_id/threads/:id" do
    @root_post = Chessboard::Post[params["id"].to_i]
    @forum     = Chessboard::Forum[params["forum_id"].to_i]
    halt 404 unless @forum
    halt 404 unless @root_post
    halt 400 unless @root_post.forum_id == @forum.id

    # Somehow one can't eager-load the authors on a recursive dataset,
    # so this needs to be done manually.
    @thread_info = construct_thread_info(@root_post, logged_in_user)

    if logged_in?
      # Thread view displays the entire thread, so mark
      # all posts in this thread as read by this user.
      mark_posts_as_read([@root_post.id, @root_post.descendants.map(&:id)].flatten)
    end

    # Increase view count
    @root_post.update(:views => @root_post.views + 1)
    @reply_count = @root_post.children.count # children are eager-loaded here already, so no extra query

    erb :thread
  end

  private

  def mark_posts_as_read(all_post_ids)
    unread_post_ids = all_post_ids - Chessboard::Application::DB[:read_posts].where(:post_id => all_post_ids, :user_id => logged_in_user.id).select_map(:post_id)
    Chessboard::Application::DB[:read_posts].import([:user_id, :post_id], Array.new(unread_post_ids.length){[logged_in_user.id, unread_post_ids.pop]})
  end

  # This method is to overcome the problem that one can't
  # eager-load cascades on recursive datasets in Sequel (bug?).
  # It returns a hash containing all authors and attachments for
  # all posts in the thread below +post+ in this form:
  # {:authors =>
  #   {<uid> =>
  #     {:user => User instance, :post_count => total post count of this user},
  #    …},
  #  :attachments =>
  #    {<post_id> =>
  #      {<aid> => Attachment instance},
  #       …},
  #    …},
  #  :watched_posts => [list_of_post_ids]
  # }
  def construct_thread_info(post, logged_in_user)
    result = {:authors => {}, :attachments => {}}

    Chessboard::User
      .where(
        :id => [post.author_id, post.descendants.map(&:author_id)].flatten.uniq)
      .each do |user|

      result[:authors][user.id] = {:user       => user,
                                   :post_count => user.posts_dataset.count}
    end

    # Ensure posts with no attachments get an empty attachments hash
    result[:attachments][post.id] = {}
    post.descendants.map(&:id).each{|id| result[:attachments][id] = {}}

    Chessboard::Attachment
      .where(
        :post_id => [post.id,
                     post.descendants.map(&:id)].flatten)
      .order(Sequel.asc(:filename))
      .each do |attachment|

      result[:attachments][attachment.post_id][attachment.id] = attachment
    end

    if logged_in_user
      result[:watched_posts] = logged_in_user.watched_posts_dataset.select_map(:id)
    else
      result[:watched_posts] = []
    end

    result
  end

end
