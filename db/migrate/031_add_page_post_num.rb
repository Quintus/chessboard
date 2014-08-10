class AddPagePostNum < ActiveRecord::Migration
  def self.up
    add_column :global_configurations, :page_post_num, :integer, :default => 15
  end

  def self.down
    remove_column :global_configurations, :page_post_num
  end
end
