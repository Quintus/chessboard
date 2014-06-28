# -*- coding: utf-8 -*-
class User < ActiveRecord::Base

  validates :nickname, :presence => true, :uniqueness => true
  validates :email, :presence => true, :format => /\A.*?@.*\Z/
  validates :encrypted_password, :presence => true
  validates :settings, :presence => true

  has_many :posts, :foreign_key => :author_id
  has_one :settings

  has_and_belongs_to_many :moderated_forums, :class_name => "Forum", :join_table => "moderation"
  before_validation :setup_settings

  # Specify a new password.
  def password=(new_password)
    if new_password.to_s.length > 8
      self.encrypted_password = BCrypt::Password.create(new_password)
    else
      raise(ArgumentError, "Password to short!")
    end
  end

  # Process +password+ and compare it with the encrypted password
  # we have in our database. Returns true on success, false otherwise.
  def authenticate(password)
    BCrypt::Password.new(encrypted_password) == password
  end

  # Returns true if this user is allowed to moderate any specific
  # forum.
  def moderator?
    !moderated_forums.empty?
  end

  # Returns true if this user has higher privileges, i.e. it’s
  # an administrator or a moderator (or both).
  def privileged?
    admin? || moderator?
  end

  # Returns true if the given Forum instance is moderated by this user.
  # Also returns true if the user is admin. Returns false if +forum+ is nil.
  def moderates?(forum)
    return true if admin?
    return false unless forum
    moderated_forums.include?(forum)
  end

  # Returns the translated string for
  # * "Member"
  # * "Moderator"
  # * "Administrator"
  # depending on the user’s membership status.
  def membership
    return I18n.t("membership.administrator") if admin?
    return I18n.t("membership.moderator") if moderator?
    I18n.t("membership.member")
  end

  private

  def setup_settings
    self.settings ||= Settings.new
  end

end
