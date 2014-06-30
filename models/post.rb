# -*- coding: utf-8 -*-
class Post < ActiveRecord::Base

  MARKUP_LANGUAGES = %w[BBCode Markdown].freeze

  validates :content, :presence => true
  validates :markup_language, :presence => true, :inclusion => { :in => MARKUP_LANGUAGES }
  validates :author, :presence => true

  belongs_to :topic
  belongs_to :author, :class_name => "User"
  has_many :reports, :dependent => :destroy

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

end
