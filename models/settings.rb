# -*- coding: utf-8 -*-
class Settings < ActiveRecord::Base

  validates :user, :presence => true
  validates :preferred_markup_language, :presence => true, :inclusion => {:in => Post::MARKUP_LANGUAGES}
  validates :language, :inclusion => { :in => I18n.available_locales.map(&:to_s) }
  validate :validate_avatar_image_format

  belongs_to :user

  # Always return’s the user’s Gravatar URI. This can directly be
  # placed in an image tag.
  def gravatar
    md5 = Digest::MD5.hexdigest(user.email.strip)

    "https://www.gravatar.com/avatar/#{md5}?s=80"
  end

  # Always returns the user’s normal avatar URI. This can directly
  # be placed in an image tag, but be sure to check you didn’t
  # get +nil+ (which is the case when no avatar was uploaded yet).
  def normal_avatar
    path = avatar_path
    return nil if path.blank?

    if File.exists?(Padrino.root("public", "images", "avatars", path))
      "/images/avatars/#{path}"
    else
      nil
    end
  end

  # Depending on the user’s settings, returns either #gravatar
  # or #normal_avatar.
  def avatar
    if use_gravatar
      gravatar
    else
      normal_avatar
    end
  end

  private

  def validate_avatar_image_format
    unless avatar_path.blank?
      img = MiniMagick::Image.open(Padrino.root("public", "images", "avatars", avatar_path))
      if img[:width] > Chessboard.config.maximum_avatar_dimension || img[:height] > Chessboard.config.maximum_avatar_dimension
        errors.add(:avatar_path, I18n.t("errors.settings.avatar_path.max_dimension", :dim => Chessboard.config.maximum_avatar_dimension))
      end
    end
  end

end
