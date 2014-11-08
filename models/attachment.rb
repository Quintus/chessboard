class Attachment < ActiveRecord::Base

  validates :filename, :presence => true, :format => /\A[[:alnum:]_\-\.]+\z/
  validate :validate_unique_filename
  validate :validate_size
  validate :validate_mime_type

  belongs_to :post

  before_destroy do
    logger.info "Deleting destroyed attachment's file '#{self.full_path}'"
    File.delete(self.full_path)
  end

  # Creates an Attachment from a given basename, a short description,+
  # and the Rack file upload hash. Raises a RuntimeError if for some
  # reason the attachment fails to save to the database.
  def self.from_upload(filename, description, uploadhsh)
    attachment = new
    attachment.filename = filename
    attachment.description = description # may be nil

    logger.info "Writing attachment '#{attachment.filename}'"
    File.open(attachment.full_path, "wb") do |f|
      while chunk = uploadhsh[:tempfile].read(1024)
        f.write(chunk)
      end
    end

    if attachment.save
      attachment
    else
      File.delete(attachment.full_path) if File.exist?(attachment.full_path)
      raise("Failed to save attachment '#{attachment.path}'!")
    end
  end

  # Full path to the attachment file on the filesystem.
  def full_path
    # The path must be unique to prevent overwriting of existing
    # attachments. This is guaranteed by including the post ID
    # into the filename. Multiple attachments of the same name
    # are not allowed in one post.
    Padrino.root("public", "attachments", post.id.to_s, filename)
  end

  # Absolute URL you can use to reference the file.
  def full_uri
    "/attachments/#{post.id}/#{filename}"
  end

  # Returns the MIME type of the underlying file as determined
  # by the file(1) command, as a string.
  def mime_type
    IO.popen([Chessboard.config.attachment_file_command, "--brief", "--mime-type", full_path]) do |io|
      io.read.strip
    end
  end

  private

  def validate_unique_filename
    if post.attachments.pluck(:filename).index(filename)
      errors.add(:filename, I18n.t("errors.post.filename.taken", :filename => filename))
    end
  end

  def validate_size
    if File.size(full_path) > Chessboard.config.attachment_max_size
      errors.add(:filename, I18n.t("errors.post.filename.too_large", :filename => filename, :maximum => Chessboard.config.attachment_max_size))
    end
  end

  def validate_mime_type
    unless Chessboard.config.attachment_allowed_mime_types.include?(mime_type)
      errors.add(:filename, I18n.t("errors.post.filename.disallowed_mime", :filename => filename))
    end
  end

end
