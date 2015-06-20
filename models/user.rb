# -*- coding: utf-8 -*-
class User < ActiveRecord::Base

  validates :nickname, :presence => true, :uniqueness => true, :format => {:with => /\A[[:graph:]]+\Z/}
  validates :email, :presence => true, :format => /\A.*?@.*\Z/
  validates :encrypted_password, :presence => true
  validates :settings, :presence => true
  validates :signature, :length => {:maximum => 1024}
  validates :location, :length => {:maximum => 30}
  validates :profession, :length => {:maximum => 1024}
  validates :jabber_id, :length => {:maximum => 1024}
  validates :pgp_key, :length => {:maximum => 50} # length of $ gpg --fingerprint
  validate :validate_password_length

  has_many :topics, :foreign_key => :author_id, :dependent => :destroy
  has_many :posts, :foreign_key => :author_id, :dependent => :destroy
  has_many :personal_messages, :foreign_key => :author_id, :dependent => :destroy
  has_many :personal_posts, :foreign_key => :author_id, :dependent => :destroy
  has_many :reports, :dependent => :destroy
  has_many :received_warnings, :class_name => "Warning", :foreign_key => "warned_user_id", :dependent => :destroy
  has_many :issued_warnings, :class_name => "Warning", :foreign_key => "warning_user_id", :dependent => :destroy
  has_many :received_moderations, :class_name => "ModerationLogEntry", :foreign_key => "targetted_user_id", :dependent => :nullify
  has_many :issued_moderations, :class_name => "ModerationLogEntry", :foreign_key => "moderator_id", :dependent => :destroy # If the moderator deletes his account, delete the corresponding log entries.
  has_one :settings, :dependent => :destroy
  has_one :avatar, :dependent => :destroy
  has_one :registration_token, :dependent => :destroy

  has_and_belongs_to_many :moderated_forums, :class_name => "Forum", :join_table => "moderation"
  has_and_belongs_to_many :read_topics, :class_name => "Topic", :join_table => "read_topics"
  has_and_belongs_to_many :read_pms, :class_name => "PersonalMessage", :join_table => "read_pms"
  # Note this includes all the PMs we authored (i.e. #personal_messages)
  has_and_belongs_to_many :allowed_pms, :class_name => "PersonalMessage", :join_table => "pm_access"
  has_and_belongs_to_many :watched_topics, :class_name => "Topic", :join_table => "watchers"

  before_validation :setup_settings
  before_validation :ensure_protocol_prefix

  # This is a hash for plugins to use. Each plugin shall use a subhash
  # under the key of its name, i.e. {:FooPlugin => {:key1 => "val1", ...}}.
  serialize :plugin_data, Hash

  # Specify a new password.
  def password=(new_password)
    if new_password.to_s.length >= 8
      self.encrypted_password = BCrypt::Password.create(new_password)
    else
      # Do nothing and prepare for adding a validation error
      @_pwlen = new_password.length
    end
  end

  # Resets the user’s password to a random password and returns that
  # password in clear. The resource is automatically saved to the
  # database.
  def reset_password!
    newpw = Array.new(10){("a".."z").to_a.sample}.join("") # Must be long enough to pass test in #password=
    self.password = newpw
    save!
    newpw
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
    return forced_rank unless forced_rank.blank?
    return I18n.t("membership.administrator") if admin?
    return I18n.t("membership.moderator") if moderator?
    I18n.t("membership.member")
  end

  # Returns true if the User has read the given Topic.
  def read?(topic)
    read_topics.include?(topic)
  end

  # Returns true if the User has read all topics in the
  # given forum.
  def read_forum?(forum)
    read_topics  = forum.topics.joins(:users_who_read_this).where("read_topics.user_id" => id).count
    total_topics = forum.topics.count

    read_topics == total_topics
  end

  # Returns true if the User has read the given PersonalMessage.
  def read_pm?(pm)
    read_pms.include?(pm)
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

  def validate_password_length
    if defined?(@_pwlen) && @_pwlen < 8
      errors.add(:password, I18n.t("errors.user.password_too_short"))
    end
    # if @_pwlen is not defined, the resource has been modified otherwise,
    # not on the #password= setter. As encrypted_password must be present
    # (this is validated), we don’t have to revalidate it here again.
  end

end
