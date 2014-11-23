# coding: utf-8
class Attachment < ActiveRecord::Base

  # Defines the width and height of an image attachment.
  Dimensions = Struct.new(:width, :height) do
    def to_s # :nodoc:
      "#{width}x#{height}"
    end
  end

  validates :filename, :presence => true, :format => /\A[[:alnum:]_\-\.]+\z/
  validate :validate_unique_filename
  validate :validate_size
  validate :validate_mime_type

  belongs_to :post

  before_destroy do
    logger.info "Deleting destroyed attachment's file '#{full_path}'"
    File.delete(full_path)
    Dir.delete(File.dirname(full_path)) if Dir.entries(File.dirname(full_path)).count == 2 # . and ..
  end

  # Creates an Attachment for a post from a short description
  # and the Rack file upload hash. Raises database save! errors
  # if sav!ng fails.
  def self.from_upload!(post, description, uploadhsh)
    attachment = new
    attachment.filename = uploadhsh[:filename].strip.gsub(" ", "_")
    attachment.description = description # may be nil
    attachment.post = post

    logger.info "Writing attachment '#{attachment.filename}'"
    Dir.mkdir(File.dirname(attachment.full_path)) unless File.directory?(File.dirname(attachment.full_path))

    File.open(attachment.full_path, "wb") do |f|
      while chunk = uploadhsh[:tempfile].read(1024)
        f.write(chunk)
      end
    end

    begin
      attachment.save!
    rescue
      logger.error "Failed to save attachment: #{attachment.full_path}"
      File.delete(attachment.full_path) if File.exist?(attachment.full_path)
      raise # re-raise
    end

    attachment
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
    execute_command(Chessboard.config.attachment_file_command, "--brief", "--mime-type", full_path)
  end

  # Returns a Dimension instance for an image attachment. Raises
  # ArgumentError if this isn’t an image.
  def dimensions
    raise(ArgumentError, "'#{full_path}' is not an image!") unless image?

    img = MiniMagick::Image.open(full_path)
    Dimensions.new(img[:width], img[:height])
  end

  # Returns true if this attachment is an image, false otherwise.
  def image?
    mime_type.start_with?("image/")
  end

  private

  def validate_unique_filename
    if post.attachments.pluck(:filename).index(filename)
      errors.add(:filename, I18n.t("errors.post.filename.taken", :filename => filename))
    end
  end

  def validate_size
    config = GlobalConfiguration.instance
    if File.size(full_path) > config.maximum_attachment_size
      errors.add(:filename, I18n.t("errors.post.filename.too_large", :filename => filename, :maximum => config.maximum_attachment_size))
    end
  end

  def validate_mime_type
    unless GlobalConfiguration.instance.attachment_mime_type_allowed?(mime_type)
      errors.add(:filename, I18n.t("errors.post.filename.disallowed_mime", :filename => filename))
    end
  end

  def execute_command(*args)
    logger.debug("Command: #{args.inspect}")

    IO.popen(args) do |io|
      str = io.read.strip
      logger.debug("Command result: #{str.inspect}")
      str
    end
  end

end
