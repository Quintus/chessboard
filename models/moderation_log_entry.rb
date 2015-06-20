class ModerationLogEntry < ActiveRecord::Base
  validates :moderator_id, :presence => true
  validates :action, :presence => true

  belongs_to :moderator,      :class_name => "User", :foreign_key => "moderator_id"
  belongs_to :targetted_user, :class_name => "User", :foreign_key => "targetted_user_id"
  belongs_to :post
end
