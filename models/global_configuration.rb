class GlobalConfiguration < ActiveRecord::Base

  validates :maximum_avatar_dimension, :numericality => {:only_integer => true, :greater_than => 0}
  validates :warning_expiration, :numericality => {:only_integer => true, :greater_than_or_equal_to => 0}
  validates :registration_expiration, :numericality => {:only_integer => true, :greater_than => 0}
  validates :page_post_num, :numericality => {:only_integer => true, :greater_than_or_equal_to => 5}
  validate :check_singleton

  def self.instance
    first
  end

  private

  def check_singleton
    if GlobalConfiguration.count >= 1 && new_record?
      errors[:base] << "Can only exist once."
    end
  end

end
