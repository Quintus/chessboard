class Settings < ActiveRecord::Base

  validates :user, :presence => true
  validates :preferred_markup_language, :presence => true, :inclusion => {:in => Post::MARKUP_LANGUAGES}
  validates :language, :inclusion => { :in => I18n.available_locales.map(&:to_s) }
  validate :validate_avatar_image_format

  belongs_to :user

  def avatar
    if use_gravatar
      # TODO
      nil
    else
      path = avatar_path
      return nil if path.blank?

      if File.exists?(Padrino.root("public", "images", "avatars", path))
        "/images/avatars/#{path}"
      else
        nil
      end
    end
  end

  private

  def validate_avatar_image_format
    unless avatar_path.blank?
      img = MiniMagick::Image.open(Padrino.root("public", "images", "avatars", avatar_path))
      # TODO
    end
  end

end
