class Forum < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true
  validates :description, :presence => true

  has_and_belongs_to_many :moderators, :class_name => "User", :join_table => "moderation"
  belongs_to :forum_group
  has_many :topics

  # Returns all topics for this forum plus any announcements, in
  #  this order:
  # 1. All announcements, ordered reversely by update
  # 2. All stickies for this forum, ordered reversely by update
  # 3. All normal topics for this forum, ordered reversely by update
  def categorized_topics
    # First announcements
    result = Topic.where(:announcement => true).joins(:posts).group("topics.id").order("posts.updated_at DESC")

    # Next sticky topics
    result += topics.where(:sticky => true).joins(:posts).group("topics.id").order("posts.updated_at DESC")

    # Finally normal topics
    result += topics.where(:sticky => false, :announcement => false).joins(:posts).group("topics.id").order("posts.updated_at DESC")

    # Result
    result
  end

end
