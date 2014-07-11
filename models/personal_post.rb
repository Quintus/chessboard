class PersonalPost < ActiveRecord::Base

  validates :content, :presence => true
  validates :author, :presence => true
  validates :markup_language, :markup_language => true

  belongs_to :personal_message
  belongs_to :author, :class_name => "User"

end
