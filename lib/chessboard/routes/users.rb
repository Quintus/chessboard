class Chessboard::Application < Sinatra::Base

  get "/users/:id" do
    halt 401 unless logged_in?
    @user = Chessboard::User[params["id"].to_i]

    halt 404 unless @user

    erb :user
  end

  # Should be a DELETE method, but browsers don't support that.
  post "/users/:id/delete" do
    halt 401 unless logged_in?
    @user = Chessboard::User[params["id"].to_i]

    halt 404 unless @user
    halt 403 unless @user == logged_in_user

    @user.move_all_posts_to_other_user_id!(Chessboard::User::guest_id)
    @user.destroy

    message t.settings.deleted_account
    session["user"] = nil # log the user out
    redirect "/"
  end

end
