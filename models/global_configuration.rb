class GlobalConfiguration < ActiveRecord::Base

  validates :maximum_avatar_dimension, :numericality => {:only_integer => true, :greater_than => 0}
  validates :warning_expiration, :numericality => {:only_integer => true, :greater_than_or_equal_to => 0}
  validates :registration_expiration, :numericality => {:only_integer => true, :greater_than => 0}
  validates :page_post_num, :numericality => {:only_integer => true, :greater_than_or_equal_to => 5}
  validates :page_topic_num, :numericality => {:only_integer => true, :greater_than_or_equal_to => 5}
  validates :maximum_attachment_size, :numericality => {:only_integer => true, :greater_than => 0}
  validates :allowed_attachment_mime_types, :presence => true
  validate :check_singleton

  # This is a hash for plugins to use. Each plugin shall use a subhash
  # under the key of its name, i.e. {:FooPlugin => {:key1 => "val1", ...}}.
  serialize :plugin_data, Hash

  def self.instance
    first
  end

  # Returns true if the given MIME type is allowed as an attachment,
  # otherwise returns false. Checks the allowed_attachment_mime_types
  # option.
  def attachment_mime_type_allowed?(type)
    allowed_attachment_mime_types.split(/,\s?/).include?(type)
  end

  private

  def check_singleton
    if GlobalConfiguration.count >= 1 && new_record?
      errors[:base] << "Can only exist once."
    end
  end

end
