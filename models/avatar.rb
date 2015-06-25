class Avatar < ActiveRecord::Base

  validates :path, :presence => true
  validate :validate_avatar_image_format
  belongs_to :user

  # Remove the now useless file
  before_destroy do
    logger.info "Deleting destroyed avatar's file '#{self.full_path}'"
    File.delete(self.full_path)
  end

  def upload!(user, hsh)
    self.path = user.id.to_s + File.extname(hsh[:filename])
    self.user = user

    logger.info "Writing avatar '#{path}'"
    File.open(full_path, "wb") do |f|
      while chunk = hsh[:tempfile].read(1024)
        f.write(chunk)
      end
    end

    if save
      true
    else
      logger.warn "Saving failed, deleting avatar '#{path}' again."
      File.delete(full_path) if File.exist?(full_path)
      false
    end
  end

  def full_path
    Padrino.root("public", "images", "avatars", path)
  end

  def full_uri
    "/images/avatars/#{path}"
  end

  private

  def validate_avatar_image_format
    unless path.blank?
      img = MiniMagick::Image.open(Padrino.root("public", "images", "avatars", path))
      if img[:width] > GlobalConfiguration.instance.maximum_avatar_dimension || img[:height] > GlobalConfiguration.instance.maximum_avatar_dimension
        errors.add(:path, I18n.t("errors.avatar.path.max_dimension", :dim => GlobalConfiguration.instance.maximum_avatar_dimension))
      end
    end
  end

end
