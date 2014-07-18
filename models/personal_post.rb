class PersonalPost < ActiveRecord::Base

  validates :content, :presence => true
  validates :author, :presence => true
  validates :personal_message, :presence => true
  validates :markup_language, :markup_language => true

  belongs_to :personal_message
  belongs_to :author, :class_name => "User"

  after_destroy :delete_empty_pm

  private

  # Ensure we don't have empty PMs after the last post
  # has been deleted.
  def delete_empty_pm
    personal_message.destroy! if personal_message.posts.empty?
  end

end
