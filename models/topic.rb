class Topic < ActiveRecord::Base

  validates :title, :presence => true
  validates :author, :presence => true

  has_many :posts
  belongs_to :forum
  belongs_to :author, :class_name => "User"

end
