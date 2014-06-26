class AddViewsToTopics < ActiveRecord::Migration
  def self.up
    add_column :topics, :views, :integer, :default => 0
  end

  def self.down
    remove_column :topics, :views
  end
end
