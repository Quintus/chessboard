RACK_ENV = 'test' unless defined?(RACK_ENV)
require File.expand_path('../../config/boot', __FILE__)

ENV["RACK_ENV"] = "test"
puts "Resetting test database..."
system("bundle exec rake db:drop db:create db:migrate")

4.times{ Fabricate(:user) }

class MiniTest::Spec
  include Rack::Test::Methods

  # You can use this method to custom specify a Rack app
  # you want rack-test to invoke:
  #
  #   app Chessboard::App
  #   app Chessboard::App.tap { |a| }
  #   app(Chessboard::App) do
  #     set :foo, :bar
  #   end
  #
  def app(app = nil, &blk)
    @app ||= block_given? ? app.instance_eval(&blk) : app
    @app ||= Padrino.application
  end
end
