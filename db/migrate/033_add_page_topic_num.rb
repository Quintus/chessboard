class AddPageTopicNum < ActiveRecord::Migration
  def self.up
    add_column :global_configurations, :page_topic_num, :integer, :default => 15
  end

  def self.down
    remove_column :global_configurations, :page_topic_num
  end
end
