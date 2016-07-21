require "sinatra/base"
require_relative "lib/chessboard"

class Chessboard::Application < Sinatra::Base
  enable :sessions
end
