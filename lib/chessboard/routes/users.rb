class Chessboard::Application < Sinatra::Base

  get "/users/:id" do
    halt 401 unless logged_in?
    @user = Chessboard::User[params["id"].to_i]

    halt 404 unless @user

    erb :user
  end

end
