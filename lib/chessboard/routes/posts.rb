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

    params["tags"] ||= {}
    params["attachments"] ||= []

    tags = Chessboard::Tag.where(:id => params["tags"].keys.map(&:to_i)).all

    @post      = nil
    message_id = nil
    begin
      @post      = construct_post(params, @forum)
      message_id = @post.send_to_mailinglist(tags, params["attachments"])
    rescue RangeError, Sequel::ValidationFailed => e
      @tags = Chessboard::Tag.order(Sequel.asc(:name))

      if e.class == RangeError  # Attachment size too large
        halt 413, erb(:new_post)
      else
        user_error!
        halt 422, erb(:new_post)
      end
    end

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

    # Do not allow tags in replies. While technically possible, this
    # is confusing to the user as that part of the UI appears to have
    # no use (tags on replies are not shown anywhere).
    @tags = []

    @thread_info = construct_thread_info(@post, logged_in_user)

    erb :reply
  end

  post "/forums/:forum_id/posts/:id/reply" do
    halt 401 unless logged_in?

    @forum = Chessboard::Forum[params["forum_id"].to_i]
    @parent_post = Chessboard::Post[params["id"].to_i]

    halt 404 unless @parent_post
    halt 404 unless @forum

    params["attachments"] ||= []
    params["tags"] ||= {}
    tags = Chessboard::Tag.where(:id => params["tags"].keys.map(&:to_i)).all

    # If the user is not subscribed to the mailinglist behind
    # this forum, do that now.
    unless logged_in_user.subscribed_to_mailinglist?(@forum)
      logged_in_user.subscribe_to_mailinglist(@forum)
    end

    @post      = nil
    message_id = nil
    begin
      @post        = construct_post(params, @forum)
      @post.parent = @parent_post
      message_id   = @post.send_to_mailinglist(tags, params["attachments"])
    rescue RangeError, Sequel::ValidationFailed => e
      @post            = Chessboard::Post[params["id"].to_i]
      @tags            = Chessboard::Tag.order(Sequel.asc(:name))
      @thread_info     = construct_thread_info(@post, logged_in_user)
      @suggested_title = @post.title

      if e.class == RangeError  # Attachment size too large
        halt 413, erb(:reply)
      else
        user_error!
        halt 422, erb(:reply)
      end
    end

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

  get "/forums/:forum_id/posts/:id/edit" do
    halt 401 unless logged_in?

    @forum = Chessboard::Forum[params["forum_id"].to_i]
    @origpost  = Chessboard::Post[params["id"].to_i]

    halt 404 unless @origpost
    halt 404 unless @forum
    halt 400 unless @origpost.forum == @forum
    halt 403 unless @origpost.author_id == logged_in_user.id || logged_in_user.admin?

    if @origpost.editable?
      @suggested_title   = @origpost.title
      @suggested_content = @origpost.content

      if @origpost.thread_starter?
        @tags = Chessboard::Tag.order(Sequel.asc(:name)).all
      else
        @post        = @origpost.parent
        @thread_info = construct_thread_info(@post, logged_in_user)
        # Again, no tags in replies
        @tags = []
      end

      erb :edit_post
    else
      alert t.posts.cannot_edit
      redirect post_url(@origpost, @forum)
    end
  end

  post "/forums/:forum_id/posts/:id/edit" do
    halt 401 unless logged_in?

    @forum = Chessboard::Forum[params["forum_id"].to_i]
    @origpost  = Chessboard::Post[params["id"].to_i]

    halt 404 unless @origpost
    halt 404 unless @forum
    halt 400 unless @origpost.forum == @forum
    halt 403 unless @origpost.author_id == logged_in_user.id || logged_in_user.admin?

    if @origpost.editable?
      params["attachments"] ||= []
      params["tags"] ||= {}
      tags = Chessboard::Tag.where(:id => params["tags"].keys.map(&:to_i)).all

      # If the user is not subscribed to the mailinglist behind
      # this forum, do that now.
      unless logged_in_user.subscribed_to_mailinglist?(@forum)
        logged_in_user.subscribe_to_mailinglist(@forum)
      end

      if @origpost.thread_starter?
        @parent_post = nil
      else
        # Note how the parent post is set to the edited post's parent.
        # Since the original post (@origpost) is going to be deleted
        # further below, this ensures that the reply chain stays valid
        # if Chessboard is used solely (a reply on the mailinglist to the
        # deleted may happen still, but Chessboard can handle that by searching
        # the parent references until a match is found).
        @parent_post = @origpost.parent
      end

      @post      = nil
      message_id = nil
      begin
        @post              = construct_post(params, @forum)
        @post.parent       = @parent_post if @parent_post
        @post.edited_at    = Time.now.utc
        @post.edited_msgid = @origpost.message_id
        message_id         = @post.send_to_mailinglist(tags, params["attachments"])
      rescue RangeError, Sequel::ValidationFailed => e
        @origpost        = Chessboard::Post[params["id"].to_i]
        @suggested_title = @origpost.title

        if @origpost.thread_starter?
          @tags = Chessboard::Tag.order(Sequel.asc(:name))
        else
          @tags = []
          @thread_info = construct_thread_info(@origpost, logged_in_user)
        end

        if e.class == RangeError  # Attachment size too large
          halt 413, erb(:edit_post)
        else
          user_error!
          halt 422, erb(:edit_post)
        end
      end

      # Remove original post from database so that it is not part of
      # any discussion anymore.
      @origpost.destroy

      # Give the email infrastructure opportunity to deliver the email.
      sleep 60

      if @post = Chessboard::Post.where(:message_id => message_id).first # Single = intended
        @post.update(:ip => request.ip) unless Chessboard::Configuration[:max_ip_store_timespan].nil?

        message t.posts.edited
        redirect post_url(@post.thread_starter)
      else
        alert t.posts.creation_failed(Chessboard::Configuration[:admin_email])
        redirect "/forums/#{@forum.id}"
      end
    else
      # If this happens, someone replied or time expired during editing
      alert t.posts.cannot_edit
      redirect post_url(@origpost, @forum)
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

  get "/posts/:id" do
    post = Chessboard::Post[params["id"].to_i]
    halt 404 unless post

    redirect post_url(post), 307
  end

  get "/forums/:forum_id/posts/:id/tags" do
    halt 401 unless logged_in?
    halt 403 unless logged_in_user.admin?
    @post  = Chessboard::Post[params["id"].to_i]
    @forum = Chessboard::Forum[params["forum_id"].to_i]

    halt 404 unless @post
    halt 404 unless @forum
    halt 400 unless @post.forum == @forum

    @tags         = Chessboard::Tag.order(Sequel.asc(:name)).all
    @post_tag_ids = @post.tags_dataset.select_map(:id)

    erb :edit_tags
  end

  post "/forums/:forum_id/posts/:id/tags" do
    halt 401 unless logged_in?
    halt 403 unless logged_in_user.admin?
    @post  = Chessboard::Post[params["id"].to_i]
    @forum = Chessboard::Forum[params["forum_id"].to_i]

    halt 404 unless @post
    halt 404 unless @forum
    halt 400 unless @post.forum == @forum

    params["tags"] ||= {}
    tags = Chessboard::Tag.where(:id => params["tags"].keys.map(&:to_i)).all

    @post.remove_all_tags
    tags.each{|tag| @post.add_tag(tag)}

    message t.admin.edited_tags
    redirect post_url(@post, @forum)
  end

  private

  def construct_post(params, forum)
    post            = Chessboard::Post.new
    post.title      = params["title"]
    post.forum      = forum
    post.author     = logged_in_user
    post.used_alias = logged_in_user.display_name

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
