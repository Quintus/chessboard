class Chessboard::Application < Sinatra::Base
  get "/forums/:forum_id/posts/:id/announce" do
    halt 403 unless logged_in? && logged_in_user.admin?
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
    halt 403 unless logged_in? && logged_in_user.admin?
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
    halt 403 unless logged_in? && logged_in_user.admin?
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
    halt 403 unless logged_in? && logged_in_user.admin?
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

  get "/forums/:forum_id/posts/:id/reply" do
    halt 403 unless logged_in?

    @forum = Chessboard::Forum[params["forum_id"].to_i]
    @post  = Chessboard::Post[params["id"].to_i]

    halt 404 unless @post
    halt 404 unless @forum
    halt 400 unless @post.forum == @forum

    @suggested_title = @post.title
    @suggested_title = "Re: #{@suggested_title}" unless @suggested_title =~ /^Re:/i
    @tags = Chessboard::Tag.order(Sequel.asc(:name))

    erb :reply
  end

  post "/forums/:forum_id/posts/:id/reply" do
    halt 403 unless logged_in?

    @forum = Chessboard::Forum[params["forum_id"].to_i]
    @parent_post = Chessboard::Post[params["id"].to_i]

    halt 404 unless @parent_post
    halt 404 unless @forum

    @post = Chessboard::Post.new
    @post.content = params["content"]
    @post.title   = params["title"]
    @post.ip      = request.ip
    @post.forum   = @forum
    @post.author  = logged_in_user
    @post.parent  = @parent_post

    # Ensure the attachments' total size does not exceed what is allowed
    if params["attachments"]
      max   = Chessboard::Configuration[:max_total_attachment_size]
      total = params["attachments"].reduce(0){|sum, hsh| sum + hsh[:tempfile].size}
      if total > max
        @attachment_error = t.posts.attachments_too_large(
          readable_bytesize(total),
          readable_bytesize(max))
        halt 413, erb(:reply)
      end
    end

    if params["tags"]
      @tags = Chessboard::Tag.where(:id => params["tags"].keys.map(&:to_i))
    else
      @tags = []
    end

    message_id = @post.send_to_mailinglist(@tags, params["attachments"] || [])

    # Give the email infrastructure opportunity to deliver the email.
    # The mailinglist monitor creates a post with the message ID set
    # to the ID generated in Post#send_to_mailinglist, hence this
    # can be used to dig out the created Post instance below.
    # Message IDs are usually unique, the rare duplicates can
    # be ignored.
    sleep 3

    message t.posts.created
    redirect post_url(Chessboard::Post.where(:message_id => message_id).first)
  end

end
