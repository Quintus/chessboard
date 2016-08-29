class Chessboard::Attachment < Sequel::Model
  many_to_one :post

  # Directory under public/ where the attachments are stored.
  STORE_SUBPATH = "attachments".freeze

  def self.attachments_dir
    File.join(Chessboard::Application.root, "public", STORE_SUBPATH)
  end

  def self.create_from_mail_attachment(attachment, post)
    obj = new
    obj.filename = escape_filename(attachment.filename)
    obj.post = post

    target_dir = File.dirname(obj.absolute_path)
    unless File.directory?(target_dir)
      FileUtils.mkdir_p(target_dir)
    end

    File.open(obj.absolute_path, "wb") do |file|
      file.write(attachment.body.decoded)
    end

    obj.save
    obj
  end


  # Ensure there are no malicious characters in attachment filenames
  # by restricting them to the Unicode set of alphanumeric characters
  # and periods.
  def self.escape_filename(filename)
    filename.gsub!(/[^[[:alnum:]]\.]/, "_")
    filename
  end

  def absolute_path
    File.join(self.class.attachments_dir, post_id.to_s, filename)
  end

  def absolute_url
    "/#{STORE_SUBPATH}/#{post_id}/#{filename}"
  end

  # Checks if this attachment's MIME type starts with "image/" and if
  # so, returns true, otherwise returns false.
  def image?
    mime_type.start_with?("image/")
  end

  private

  def before_create
    # Filename escapement for those cases where the instance was
    # not created by means of ::create_from_mail_attachment.
    # Processing those twice does not hurt (replaces "_" with "_").
    self.filename = self.class.escape_filename(filename)

    # Determine the real MIME type (rather than believing
    # whatever the email contains, which might be malicious).
    command = "file --brief --mime-type '#{absolute_path}'"
    Chessboard.logger.info("Executing: #{command}")
    self.mime_type = IO.popen(command, "r"){| io| io.read.strip }

    super
  end

  # If this object is deleted, also delete the associated file
  # ond isk.
  def after_delete
    super
    File.delete(absolute_path)
  end

end
