# Helper methods defined here can be accessed in any controller or view in the application

module Chessboard
  class App
    module UsersHelper

      def user_link(user)
        link_to(user.nickname, url(:users, :show, user.nickname))
      end

    end

    helpers UsersHelper
  end
end
