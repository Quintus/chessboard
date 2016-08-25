# config.ru
# Rack handler configuration.

require_relative "lib/chessboard"

run Chessboard::Application
