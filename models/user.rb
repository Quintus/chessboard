# -*- coding: utf-8 -*-
class User < ActiveRecord::Base

  validates :nickname, :presence => true, :uniqueness => true
  validates :email, :presence => true, :format => /\A.*?@.*\Z/
  validates :encrypted_password, :presence => true
  validates :settings, :presence => true
  validates :signature, :length => {:maximum => 1024}
  validates :location, :length => {:maximum => 30}
  validates :profession, :length => {:maximum => 1024}
  validates :jabber_id, :length => {:maximum => 1024}
  validates :pgp_key, :length => {:maximum => 50} # length of $ gpg --fingerprint

  has_many :topics, :foreign_key => :author_id
  has_many :posts, :foreign_key => :author_id
  has_many :personal_messages, :foreign_key => :author_id
  has_many :personal_posts, :foreign_key => :author_id
  has_many :reports
  has_many :received_warnings, :class_name => "Warning", :foreign_key => "warned_user_id"
  has_many :issued_warnings, :class_name => "Warning", :foreign_key => "warning_user_ud"
  has_one :settings, :dependent => :destroy
  has_one :avatar, :dependent => :destroy
  has_one :registration_token, :dependent => :destroy

  has_and_belongs_to_many :moderated_forums, :class_name => "Forum", :join_table => "moderation"
  has_and_belongs_to_many :read_topics, :class_name => "Topic", :join_table => "read_topics"
  # Note this includes all the PMs we authored (i.e. #personal_messages)
  has_and_belongs_to_many :allowed_pms, :class_name => "PersonalMessage", :join_table => "pm_access"

  before_validation :setup_settings
  before_validation :ensure_protocol_prefix

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

  # Returns true if the User has read the given Topic.
  def read?(topic)
    read_topics.include?(topic)
  end

  # Always return’s the user’s Gravatar URI. This can directly be
  # placed in an image tag.
  def gravatar
    md5 = Digest::MD5.hexdigest(email.strip)

    "https://www.gravatar.com/avatar/#{md5}?s=80"
  end

  # Always returns the user’s normal avatar URI. This can directly
  # be placed in an image tag, but be sure to check you didn’t
  # get +nil+ (which is the case when no avatar was uploaded yet).
  def normal_avatar
    av = avatar
    return nil unless av

    av.full_uri
  end

  # Depending on the user’s settings, returns either #gravatar
  # or #normal_avatar.
  def avatar_link
    if settings.use_gravatar
      gravatar
    else
      normal_avatar
    end
  end

  private

  def setup_settings
    self.settings ||= Settings.new
  end

  def ensure_protocol_prefix
    if !homepage.blank? && !homepage.start_with?("http")
      self.homepage = "http://#{homepage}"
    end
  end

end
