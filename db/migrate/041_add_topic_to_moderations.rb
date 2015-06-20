class AddTopicToModerations < ActiveRecord::Migration
  def self.up
    add_column :moderations, :topic_id, :integer
  end

  def self.down
    remove_column :moderations, :topic_id
  end
end
