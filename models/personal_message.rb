class PersonalMessage < ActiveRecord::Base

  validates :title, :presence => true
  validates :author, :presence => true

  has_many :posts, :class_name => "PersonalPost"
  belongs_to :author, :class_name => "User"

end
