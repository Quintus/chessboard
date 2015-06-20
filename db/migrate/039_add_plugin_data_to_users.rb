class AddPluginDataToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :plugin_data, :text
  end

  def self.down
    remove_column :users, :plugin_data
  end
end
