class Forum < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true
  validates :description, :presence => true

  has_and_belongs_to_many :moderators, :class_name => "User", :join_table => "moderation"
  belongs_to :forum_group
  has_many :topics
end
