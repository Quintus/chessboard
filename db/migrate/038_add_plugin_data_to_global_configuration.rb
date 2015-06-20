class AddPluginDataToGlobalConfiguration < ActiveRecord::Migration
  def self.up
    add_column :global_configurations, :plugin_data, :text
  end

  def self.down
    remove_column :global_configurations, :plugin_data
  end
end
