class Report < ActiveRecord::Base

  validates :description, :presence => true
  validates :post, :presence => true
  validates :user, :presence => true

  belongs_to :post
  belongs_to :user

end
