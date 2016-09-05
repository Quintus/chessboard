class Chessboard::Application < Sinatra::Base

  get "/admin" do
    halt 400 unless logged_in?
    halt 400 unless logged_in_user.admin?

    erb :admin
  end

  get "/admin/tags" do
    halt 400 unless logged_in?
    halt 400 unless logged_in_user.admin?

    @tags = Chessboard::Tag.order(Sequel.asc(:name))
    erb :admin_tags
  end

  post "/admin/tags" do
    halt 400 unless logged_in?
    halt 400 unless logged_in_user.admin?

    @tag = Chessboard::Tag.new
    @tag.name = params["name"]
    @tag.description = params["description"]
    @tag.color = params["color"]

    @tag.save

    message t.admin.tag_created
    redirect "/admin/tags"
  end

  get "/admin/tags/new" do
    halt 400 unless logged_in?
    halt 400 unless logged_in_user.admin?

    @tag = Chessboard::Tag.new
    erb :admin_tags_edit
  end

  get "/admin/tags/:id/edit" do
    halt 400 unless logged_in?
    halt 400 unless logged_in_user.admin?

    @tag = Chessboard::Tag[params["id"].to_i]
    halt 404 unless @tag

    erb :admin_tags_edit
  end

  # Actually this should be patch /admin/tags/:id,
  # but browsers cannot do other methods than GET
  # and POST in HTML forms.
  post "/admin/tags/:id/edit" do
    halt 400 unless logged_in?
    halt 400 unless logged_in_user.admin?

    @tag = Chessboard::Tag[params["id"].to_i]
    halt 404 unless @tag

    @tag.name = params["name"]
    @tag.description = params["description"]
    @tag.color = params["color"]

    @tag.save

    message t.admin.tag_updated
    redirect "/admin/tags"
  end

  delete "/admin/tags/:id" do
    halt 400 unless request.xhr?
    halt 400 unless logged_in?
    halt 400 unless logged_in_user.admin?

    @tag = Chessboard::Tag[params["id"].to_i]
    halt 404 unless @tag

    @tag.destroy

    200
  end

  get "/admin/forums" do
    halt 400 unless logged_in?
    halt 400 unless logged_in_user.admin?

    @forums = Chessboard::Forum.order(Sequel.asc(:ordernum)).all
    erb :admin_forums
  end

  delete "/admin/forums/:id" do
    halt 400 unless request.xhr?
    halt 400 unless logged_in?
    halt 400 unless logged_in_user.admin?

    @forum = Chessboard::Tag[params["id"].to_i]
    halt 404 unless @forum

    @forum.destroy

    200
  end

  get "/admin/forums/:id/edit" do
    halt 400 unless logged_in?
    halt 400 unless logged_in_user.admin?

    @forum = Chessboard::Forum[params["id"].to_i]
    halt 404 unless @forum

    erb :admin_forum_edit
  end

  # Again, should be PATCH but browsers don't support it
  post "/admin/forums/:id/edit" do
    halt 400 unless logged_in?
    halt 400 unless logged_in_user.admin?

    @forum = Chessboard::Forum[params["id"].to_i]
    halt 404 unless @forum

    @forum.name = params["name"]
    @forum.description = params["description"]
    @forum.ml_tag = params["ml_tag"]
    @forum.ordernum = params["ordernum"].to_i

    @forum.save

    message t.admin.forums.updated
    redirect "/admin/forums"
  end

  get "/admin/forums/:id/synchronize" do
    halt 400 unless logged_in?
    halt 400 unless logged_in_user.admin?

    if request.xhr? # AJAX request for checking the import status
      halt 400 unless $sync_ml_status # No sync in progress

      result = {:current_message => 0, :total_messages => 0}
      $sync_ml_status[:mutex].synchronize do
        result[:current_message] = $sync_ml_status[:current_message]
        result[:total_messages]  = $sync_ml_status[:total_messages]
      end

      if result[:current_message] >= result[:total_messages]
        # This means all mails have been processed and it is guaranteed
        # that the other thread does not make any further access to
        # $sync_ml_status, which we can now clean up safely thus.
        $sync_ml_status = nil
        result[:str] = t.admin.forums.synchronize_complete
        [200, {"Content-Type" => "application/json"}, result.to_json]
      else
        result[:str] = t.admin.forums.synchronize_progress result[:current_message], result[:total_messages]
        [202, {"Content-Type" => "application/json"}, result.to_json]
      end
    else # Regular request for initiating the import
      @forum = Chessboard::Forum[params["id"].to_i]
      halt 404 unless @forum
      halt 400 if $sync_ml_status # Can only import one mailinglist at a time

      # A global variable is probably a little hacky, but still cleaner
      # than any alternative approach I can come up with to get the mutex
      # over into the AJAX requests handled above.
      $sync_ml_status = {:mutex => Mutex.new, :current_message => 0, :total_messages => 0}
      Thread.new do
        @forum.sync_with_mailinglist! do |path, cur_msg, total_msgs|
          $sync_ml_status[:mutex].synchronize do
            $sync_ml_status[:current_message] = cur_msg
            $sync_ml_status[:total_messages]  = total_msgs
          end
        end
      end

      erb :admin_forum_synchronize
    end
  end

  get "/admin/forums/new" do
    halt 400 unless logged_in?
    halt 400 unless logged_in_user.admin?

    @forum = Chessboard::Forum.new
    erb :admin_forum_edit
  end

  post "/admin/forums" do
    halt 400 unless logged_in?
    halt 400 unless logged_in_user.admin?

    @forum = Chessboard::Forum.new
    @forum.name = params["name"]
    @forum.description = params["description"]
    @forum.ml_tag = params["ml_tag"]
    @forum.ordernum = params["ordernum"].to_i
    @forum.mailinglist = params["mailinglist"]

    @forum.save

    message t.admin.forums.created
    redirect "/admin/forums"
  end

end
