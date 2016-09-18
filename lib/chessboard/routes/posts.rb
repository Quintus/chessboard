class Chessboard::Application < Sinatra::Base
  get "/forums/:forum_id/posts/:id/announce" do
    halt 401 unless logged_in?
    halt 403 unless logged_in_user.admin?
    @post = Chessboard::Post[params["id"].to_i]
    @forum = Chessboard::Forum[params["forum_id"].to_i]

    halt 404 unless @post
    halt 404 unless @forum
    halt 400 unless @post.forum == @forum

    @post.announcement = true
    @post.save

    message t.posts.marked_as_announcement
    redirect "/forums/#{@forum.id}"
  end

  get "/forums/:forum_id/posts/:id/unannounce" do
    halt 401 unless logged_in?
    halt 403 unless logged_in_user.admin?
    @post = Chessboard::Post[params["id"].to_i]
    @forum = Chessboard::Forum[params["forum_id"].to_i]

    halt 404 unless @post
    halt 404 unless @forum
    halt 400 unless @post.forum == @forum

    @post.announcement = false
    @post.save

    message t.posts.unmarked_as_announcement
    redirect "/forums/#{@forum.id}"
  end

  get "/forums/:forum_id/posts/:id/stick" do
    halt 401 unless logged_in?
    halt 403 unless logged_in_user.admin?
    @post = Chessboard::Post[params["id"].to_i]
    @forum = Chessboard::Forum[params["forum_id"].to_i]

    halt 404 unless @post
    halt 404 unless @forum
    halt 400 unless @post.forum == @forum

    @post.sticky = true
    @post.save

    message t.posts.marked_as_sticky
    redirect "/forums/#{@forum.id}"
  end

  get "/forums/:forum_id/posts/:id/unstick" do
    halt 401 unless logged_in?
    halt 403 unless logged_in_user.admin?
    @post = Chessboard::Post[params["id"].to_i]
    @forum = Chessboard::Forum[params["forum_id"].to_i]

    halt 404 unless @post
    halt 404 unless @forum
    halt 400 unless @post.forum == @forum

    @post.sticky = false
    @post.save

    message t.posts.unmarked_as_sticky
    redirect "/forums/#{@forum.id}"
  end

  get "/forums/:forum_id/posts/new" do
    halt 401 unless logged_in?
    @forum = Chessboard::Forum[params["forum_id"].to_i]
    halt 404 unless @forum

    @tags = Chessboard::Tag.order(Sequel.asc(:name)).all

    erb :new_post
  end

  post "/forums/:forum_id/posts" do
    halt 401 unless logged_in?
    @forum = Chessboard::Forum[params["forum_id"].to_i]
    halt 404 unless @forum

    # If the user is not subscribed to the mailinglist behind
    # this forum, do that now.
    unless logged_in_user.subscribed_to_mailinglist?(@forum)
      logged_in_user.subscribe_to_mailinglist(@forum)
    end

        @post = nil
    begin
      @post = construct_post(params, @forum)
    rescue RangeError # Attachment size too large
      halt 413, erb(:reply)
    end

    @post.parent  = @parent_post

    params["tags"] ||= {}
    @tags = Chessboard::Tag.where(:id => params["tags"].keys.map(&:to_i)).all

    message_id = @post.send_to_mailinglist(@tags, params["attachments"] || [])

    # See reply route as to why we sleep here.
    sleep 3

    if @post = Chessboard::Post.where(:message_id => message_id).first # Single = intended
      @post.update(:ip => request.ip) unless Chessboard::Configuration[:max_ip_store_timespan].nil?

      message t.posts.created
      redirect post_url(@post)
    else
      alert t.posts.creation_failed(Chessboard::Configuration[:admin_email])
      redirect "/forums/#{@forum.id}"
    end

  end

  get "/forums/:forum_id/posts/:id/reply" do
    halt 401 unless logged_in?

    @forum = Chessboard::Forum[params["forum_id"].to_i]
    @post  = Chessboard::Post[params["id"].to_i]

    halt 404 unless @post
    halt 404 unless @forum
    halt 400 unless @post.forum == @forum

    @suggested_title = @post.title
    @suggested_title = "Re: #{@suggested_title}" unless @suggested_title =~ /^Re:/i
    @tags = Chessboard::Tag.order(Sequel.asc(:name))

    @thread_info = construct_thread_info(@post, logged_in_user)

    erb :reply
  end

  post "/forums/:forum_id/posts/:id/reply" do
    halt 401 unless logged_in?

    @forum = Chessboard::Forum[params["forum_id"].to_i]
    @parent_post = Chessboard::Post[params["id"].to_i]

    halt 404 unless @parent_post
    halt 404 unless @forum

    # If the user is not subscribed to the mailinglist behind
    # this forum, do that now.
    unless logged_in_user.subscribed_to_mailinglist?(@forum)
      logged_in_user.subscribe_to_mailinglist(@forum)
    end

    @post = nil
    begin
      @post = construct_post(params, @forum)
    rescue RangeError # Attachment size too large
      halt 413, erb(:reply)
    end

    @post.parent  = @parent_post

    params["tags"] ||= {}
    @tags = Chessboard::Tag.where(:id => params["tags"].keys.map(&:to_i)).all

    message_id = @post.send_to_mailinglist(@tags, params["attachments"] || [])

    # Give the email infrastructure opportunity to deliver the email.
    # The mailinglist monitor creates a post with the message ID set
    # to the ID generated in Post#send_to_mailinglist, hence this
    # can be used to dig out the created Post instance below.
    # Message IDs are usually unique, the rare duplicates can
    # be ignored.
    sleep 3

    if @post = Chessboard::Post.where(:message_id => message_id).first # Single = intended
      @post.update(:ip => request.ip) unless Chessboard::Configuration[:max_ip_store_timespan].nil?

      message t.posts.created
      redirect post_url(@post.thread_starter)
    else
      alert t.posts.creation_failed(Chessboard::Configuration[:admin_email])
      redirect "/forums/#{@forum.id}"
    end
  end

  # One shouldn't delete from a mail archive in general, but in case
  # of spam and illegal content there are exceptions to this rule,
  # hence such a possibility has to be provided.
  delete "/forums/:forum_id/posts/:id" do
    halt 401 unless logged_in?
    halt 403 unless logged_in_user.admin?
    halt 400 unless request.xhr?

    @forum = Chessboard::Forum[params["forum_id"].to_i]
    @post  = Chessboard::Post[params["id"].to_i]

    halt 404 unless @forum
    halt 404 unless @post
    halt 400 unless @post.forum == @forum

    @post.destroy
    200
  end

  get "/forums/:forum_id/posts/:id/report" do
    halt 401 unless logged_in?

    @forum = Chessboard::Forum[params["forum_id"].to_i]
    @post  = Chessboard::Post[params["id"].to_i]

    halt 404 unless @forum
    halt 404 unless @post
    halt 400 unless @post.forum == @forum

    send_report_mail(@post, logged_in_user)

    message t.posts.reported
    redirect "/forums/#{@forum.id}"
  end

  get "/forums/:forum_id/posts/:id/watch" do
    halt 401 unless logged_in?

    @forum = Chessboard::Forum[params["forum_id"].to_i]
    @post  = Chessboard::Post[params["id"].to_i]

    halt 404 unless @forum
    halt 404 unless @post
    halt 400 unless @post.forum == @forum
    #halt 400 if logged_in_user.watches?(@post)

    logged_in_user.watch!(@post)

    message t.posts.watched
    redirect post_url(@post.thread_starter, @forum)
  end

  get "/forums/:forum_id/posts/:id/unwatch" do
    halt 401 unless logged_in?

    @forum = Chessboard::Forum[params["forum_id"].to_i]
    @post  = Chessboard::Post[params["id"].to_i]

    halt 404 unless @forum
    halt 404 unless @post
    halt 400 unless @post.forum == @forum
    #halt 400 unless logged_in_user.watches?(@forum)

    logged_in_user.unwatch!(@post)

    message t.posts.unwatched
    redirect post_url(@post.thread_starter, @forum)
  end

  private

  def construct_post(params, forum)
    post = Chessboard::Post.new
    post.title   = params["title"]
    post.forum   = forum
    post.author  = logged_in_user

    post.content = params["content"]
    unless logged_in_user.signature.to_s.empty?
      post.content = post.content.rstrip + "\n\n-- \n" + logged_in_user.signature
    end

    # Ensure the attachments' total size does not exceed what is allowed
    if params["attachments"]
      max   = Chessboard::Configuration[:max_total_attachment_size]
      total = params["attachments"].reduce(0){|sum, hsh| sum + hsh[:tempfile].size}
      if total > max
        @attachment_error = t.posts.attachments_too_large(
          readable_bytesize(total),
          readable_bytesize(max))
        raise RangeError, "Attachment total size #{total} is too large (max allowed is #{max})!"
      end
    end

    post
  end

end
