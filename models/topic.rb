class Topic < ActiveRecord::Base

  validates :title, :presence => true
  validates :author, :presence => true

  has_many :posts
  belongs_to :forum
  belongs_to :author, :class_name => "User"
  has_and_belongs_to_many :users_who_read_this, :class_name => "User", :join_table => "read_topics"

end
