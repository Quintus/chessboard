# Helper methods defined here can be accessed in any controller or view in the application

module Chessboard
  class App
    module ForumsHelper

      # Format +time+ according to the user's settings.
      # Uses Chessboard.config.normal_time_format for
      # unauthenticated users.
      def format_time(time)
        if env["warden"].authenticated?
          timestr = env["warden"].user.settings.time_format
        else
          timestr = Chessboard.config.normal_time_format
        end

        if timestr.blank?
          if time < Time.now - 1.day
            I18n.l time, :format => :plain
          else
            I18n.t("time.time_ago_format", :time => time_ago_in_words(time))
          end
        else
          time.strftime(timestr)
        end
      end

    end

    helpers ForumsHelper
  end
end
