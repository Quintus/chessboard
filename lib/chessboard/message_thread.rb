class Chessboard::MessageThread

  # Retrieve Mail::Header objects for messages starting a thread
  # in this forum. Takes a forum hash as per the configuration
  # file and the number of thread starters to retrieve. Returns
  # an array of Mail::Header objects that is sorted in descending
  # order, i.e. the newest thread comes first and the oldest thread
  # last.
  def self.get_thread_starters(forum, count)
    # Callback is required to sort by date descending.
    mail_files = Chessboard::Configuration[:load_ml_mails].call(forum[:mailinglist])

    headerstr = ""
    thread_starters = []
    mail_files.each do |mailfile|
      headerstr.clear

      File.open(mailfile, "r") do |file|
        while line = file.readline
          break if line.strip.empty? # Divider between header and body
          headerstr << line
        end
      end

      # Just parse the mail headers; we are probably processing a lot
      # of mail and don't want unnecessary processing at this point.
      header = Mail::Header.new(headerstr)

      # Now reduce the set to the thread starters, i.e. those messages that
      # do not reference other messages.
      unless header["References"] # Cf. RFC 2822 sec. 3.6.4 on References vs. In-Reply-To.
        # Further reduce to those messages that have been posted
        # in the requested forum. If no forum is specified, keep
        # the message if this is a catchall forum.
        if header["X-Chessboard-Forum"]
          if header["X-Chessboard-Forum"] == forum[:name]
            thread_starters << header
          else
            next
          end
        elsif forum[:catchall]
          thread_starters << header
        else
          next
        end

        # If the requested amount of messages is reached, abort.
        break if thread_starters.count >= count
      end
    end

    thread_starters
  end
end
