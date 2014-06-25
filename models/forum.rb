class Forum < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true
  validates :description, :presence => true

  belongs_to :forum_group
  has_many :topics
end
