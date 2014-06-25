class Forum < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true
  validates :description, :presence => true
end
