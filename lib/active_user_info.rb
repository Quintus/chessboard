# -*- coding: utf-8 -*-

module Chessboard

  # This class handles information on active users
  # in a threadsafe way. Use ::add to mark a user as
  # active, and ::handle_active_users with a block
  # to get exclusive access to the list of active
  # users.
  class ActiveUserInfo < Struct.new(:nickname, :is_hidden, :timestamp)

    @mutex = Mutex.new
    @active_users = []

    # Separate thread to prune the list of active users from
    # outdated activity timestamps every fourth of the configured
    # online time.
    @prune_thread = Thread.new do
      loop do
        sleep Chessboard.config.online_duration / 4 # Integer division intended (performance)
        @mutex.synchronize do
          @active_users.delete_if{|u| u.timestamp + Chessboard.config.online_duration < Time.now}
        end
      end
    end

    # This is volatile information, so killing the thread in-action
    # does not hurt.
    at_exit{@prune_thread.terminate}

    # Add new activity information. Note it is not neccesary
    # to manually prune outdated info, this is done automatically
    # in a separate thread. If an activity mark for the given
    # nickname already exists, it will be deleted prior to adding
    # the new information.
    #
    # == Parameters
    # [nickname]
    #   Nickname of the active user.
    # [is_hidden]
    #   Status of the user’s hide-activity setting.
    # [timestamp]
    #   Timestamp of the user’s last activity.
    def self.add(nickname, is_hidden, timestamp)
      @mutex.synchronize do
        @active_users.delete_if{|info| info.nickname == nickname} # Ensure only one entry per user
        @active_users << new(nickname, is_hidden, timestamp)
      end
    end

    # Get exclusive access on the list of active users.
    # Usage example:
    #
    #   ActiveUserInfo.handle_active_users do |infos|
    #     infos.each{|info| puts("#{info.nickname} is active.")}
    #   end
    def self.handle_active_users
      @mutex.synchronize do
        yield(@active_users)
      end
    end

  end

end
