class Forum < ActiveRecord::Base
  validates :name, :presence => true
  validates :description, :presence => true

  has_and_belongs_to_many :moderators, :class_name => "User", :join_table => "moderation"
  belongs_to :forum_group
  has_many :topics

  # Returns all topics for this forum plus any announcements, as
  # a hash with the following keys:
  #
  # [:announcements]
  #   All announcements, ordered reversely by update
  # [:stickies]
  #   All stickies for this forum, ordered reversely by update
  # [:normal]
  #   All normal topics for this forum, ordered reversely by update
  #
  # +offset+ and +limit+ parameters are applied only to the
  # the SQL query for the +normal+ topics.
  def categorized_topics(offset = nil, limit = nil)
    result = {}

    # First announcements
    result[:announcements] = Topic.where(:announcement => true).joins(:posts).group("topics.id").order("MAX(posts.updated_at) DESC")

    # Next sticky topics
    result[:stickies] = topics.where(:sticky => true).joins(:posts).group("topics.id").order("MAX(posts.updated_at) DESC")

    # Finally normal topics
    result[:normal] = topics.where(:sticky => false, :announcement => false).joins(:posts).group("topics.id").order("MAX(posts.updated_at) DESC")
    result[:normal] = result[:normal].offset(offset) if offset
    result[:normal] = result[:normal].limit(limit) if limit

    # Result
    result
  end

end
