class AddPlugindataToPosts < ActiveRecord::Migration
  def self.up
    add_column :posts, :plugin_data, :text
  end

  def self.down
    remove_column :posts, :plugin_data
  end
end
