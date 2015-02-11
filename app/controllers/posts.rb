# -*- coding: utf-8 -*-
Chessboard::App.controllers :posts do

  before :except => [:show] do
    env["warden"].authenticate!
  end

  get :new, :map => "/topics/:topic_id/posts/new" do
    @post = Post.new(:markup_language => env["warden"].user.settings.preferred_markup_language)
    @topic = Topic.find(params["topic_id"])
    render "posts/new"
  end

  post :create, :map => "/topics/:topic_id/posts/new" do
    halt 400 unless params["post"]

    @post = Post.new(params["post"])
    @post.topic = Topic.find(params["topic_id"])
    @post.author = env["warden"].user
    @post.ip = request.ip unless Chessboard.config.ip_save_time < 0

    halt 403 if @post.topic.locked?

    # This hook can prevent saving of the post
    unless call_hook(:ctrl_post_create, :post => @post, :params => params)
      @topic = @post.topic
      return render("posts/new")
    end

    if @post.save
      if Chessboard.config.attachments_enabled && !params["attachments"].blank?
        params["attachments"].each do |attach_hsh|
          begin
            Attachment.from_upload!(@post, attach_hsh["description"], attach_hsh["attachment"])
          rescue => e
            logger.error("Failed to save attachment: #{e.class}: #{e.message}: #{e.backtrace.join('\n\t')}")
            flash[:alert] = flash[:postalert] = I18n.t("posts.failed_attachment", :name => attach_hsh["attachment"][:filename], :error => e.message)
            flash[:postid] = @post.id
            # Do not die and void the entire post just because an attachment failed to
            # upload. Redoing the upload is easier than rewriting all your text!
          end
        end
      end

      call_hook(:ctrl_post_create_final, :post => @post)

      # Honour auto-watch setting: When it is enabled, add the author to
      # the watcher list (unless already watching of course).
      if @post.author.settings.auto_watch? && !@post.topic.watchers.include?(@post.author)
        @post.topic.watchers << @post.author
      end

      # Email all watchers (except the author)
      @post.topic.watchers.where.not(:id => @post.author.id).pluck(:email, :nickname).each do |email, nickname|
        deliver :posts, :watch_email, email, nickname, @post, post_url(@post), url(:topics, :show, @post.topic.id), board_link
      end

      # Unset read mark for all users except the author
      # Sadly, mass-deletion from HABTM is not possible with ActiveRecord’s
      # query interface (only one-by-one deletion would be possible,
      # spawning a lot of SQL DELETE queries), so we do raw SQL for
      # performance reasons.
      ids = User.where.not("users.id" => @post.author.id).pluck(:id)
      ActiveRecord::Base.connection.execute("DELETE FROM read_topics WHERE read_topics.user_id IN (#{ids.join(',')}) AND read_topics.topic_id = #{@post.topic.id}")

      flash[:notice] = I18n.t("posts.created")
      redirect post_url(@post)
    else
      @topic = @post.topic
      render "posts/new"
    end
  end

  # This route redirects you to the topic :show view onto
  # the correct page with the correct anchor for the specific
  # post you requested.
  get :show, :map => "/topics/:topic_id/posts/:id" do
    topic = Topic.find(params["topic_id"])
    post  = Post.find(params["id"])

    previous_posts_count = topic.posts.where("posts.id <= ?", post.id).count
    page = (previous_posts_count.to_f / GlobalConfiguration.instance.page_post_num.to_f).ceil

    redirect url(:topics, :show, topic.id) + "?page=#{page}" + "#p#{post.id}"
  end

  get :edit, :map => "/topics/:topic_id/posts/:id/edit" do
    @post = Post.find(params["id"])
    halt 403 if @post.topic.locked?
    halt 403 unless @post.can_user_change_this?(env["warden"].user)

    @topic = @post.topic
    render "posts/edit"
  end

  put :update, :map => "/topics/:topic_id/posts/:id" do
    @post = Post.find(params["id"])
    halt 403 if @post.topic.locked?
    halt 403 unless @post.can_user_change_this?(env["warden"].user)

    # This hook can prevent saving of the post
    unless call_hook(:ctrl_post_update, :post => @post, :params => params)
      @topic = @post.topic
      return render("posts/new")
    end

    attrs = params["post"]
    attrs.merge!("ip" => request.ip) unless Chessboard.config.ip_save_time < 0
    if @post.update_attributes(attrs)
      if Chessboard.config.attachments_enabled

        # Delete requested attachments
        unless params["delete_attachments"].blank?
          params["delete_attachments"].each do |attach_hsh|
            if attach_hsh["id"] && attach_hsh["_delete"] == "on"
              Attachment.find(attach_hsh["id"]).destroy!
            end
          end
        end

        # Create new attachments
        unless params["attachments"].blank?
          params["attachments"].each do |attach_hsh|
            begin
              Attachment.from_upload!(@post, attach_hsh["description"], attach_hsh["attachment"])
            rescue => e
              logger.error("Failed to save attachment: #{e.class}: #{e.message}: #{e.backtrace.join('\n\t')}")
              flash[:alert] = I18n.t("posts.failed_attachment", :name => attach_hsh["attachment"][:filename], :error => e.message)
            end
          end
        end
      end

      flash[:notice] = I18n.t("posts.updated")
      redirect post_url(@post)
    else
      @topic = @post.topic
      render "posts/edit"
    end
  end

  delete :destroy, :map => "/topics/:topic_id/posts/:id" do
    @post = Post.find(params["id"])
    halt 403 if @post.topic.locked?
    halt 403 unless @post.can_user_change_this?(env["warden"].user)

    forum = @post.topic.forum

    if @post.destroy
      flash[:notice] = I18n.t("posts.deleted")

      # Destroying the last post of a topic will automatically destroy
      # the topic; we cannot rely on a topic existing here anymore, so
      # redirect to the forum instead.
      redirect url(:forums, :show, forum.id)
    else
      flash[:alert] = "Failed to delete posting."
      redirect url(:topics, :show, @post.topic.id)
    end
  end

end
