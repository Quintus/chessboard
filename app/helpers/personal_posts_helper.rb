# Helper methods defined here can be accessed in any controller or view in the application

module Chessboard
  class App
    module PersonalPostsHelper

      # Return the canonical #url for the given PersonalPost instance.
      def ppost_url(pm_post)
        url(:personal_messages, :show, pm_post.personal_message.id) + "#p#{pm_post.id}"
      end

    end

    helpers PersonalPostsHelper
  end
end
