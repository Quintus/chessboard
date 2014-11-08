# -*- coding: utf-8 -*-
class Post < ActiveRecord::Base

  # Default markup language. This one is built right into
  # Chessboard itself and is not provided via plugins.
  DEFAULT_MARKUP_LANGUAGE = "BBCode".freeze

  validates :content, :presence => true
  validates :author, :presence => true
  validates :markup_language, :markup_language => true

  belongs_to :topic
  belongs_to :author, :class_name => "User"
  has_many :reports, :dependent => :destroy
  has_many :attachments, :dependent => :destroy

  before_destroy :delete_empty_topic

  # Returns a list of all available markup language names,
  # including both DEFAULT_MARKUP_LANGUAGE and all the
  # plugin-defined languages.
  def self.all_markup_languages
    [Post::DEFAULT_MARKUP_LANGUAGE] + Chessboard::Plugin.plugin_markup_languages.map(&:name)
  end

  # Checks if +user+ has sufficient privileges to change this
  # posting. This is the case if:
  # * The user is an administrator.
  # * The user posted this posting originally.
  # * The user is a moderator in the forum the post’s topic has
  #   been posted in.
  def can_user_change_this?(user)
    return true if user.admin?
    return true if self.author == user
    return true if user.moderates?(self.topic.forum)
    false
  end

  # Returns true if this post is the first post of the topic
  # it belongs to, false otherwise.
  def op?
    topic.posts.first == self
  end

  private

  def delete_empty_topic
    # If we are the only post in our topic, delete the entire topic.
    if topic.posts.count == 1
      # Note that #delete does not run callbacks on the topic,
      # neither does in honour :dependent. The latter is what we
      # want here as the topic instance would otherwise
      # delete all its dependent posts (which only is this
      # post), resulting in an infinite recursion.
      topic.delete
    end
  end

end
