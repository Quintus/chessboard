# -*- coding: utf-8 -*-
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
          if time < Time.now - 2.days
            I18n.l time, :format => :plain
          else
            I18n.t("time.time_ago_format", :time => time_ago_in_words(time))
          end
        else
          time.strftime(timestr)
        end
      end

      # Absolute URL for the forum’s root page. If the current
      # request came in over SSL, returns an HTTPS link, otherwise
      # a normal HTTP one. Contains a trailing slash.
      def board_link
        if request.ssl?
          "https://#{Chessboard.config.domain}/"
        else
          "http://#{Chessboard.config.domain}/"
        end
      end

    end

    helpers ForumsHelper
  end
end
