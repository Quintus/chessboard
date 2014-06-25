class User < ActiveRecord::Base

  validates :nickname, :presence => true, :uniqueness => true
  validates :email, :presence => true, :format => /\A.*?@.*\Z/
  validates :rank, :presence => true

end
