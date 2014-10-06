class ForumGroup < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true

  has_many :forums, :dependent => :destroy
end
