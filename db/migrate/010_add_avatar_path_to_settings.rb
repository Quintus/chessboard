class AddAvatarPathToSettings < ActiveRecord::Migration
  def self.up
    add_column :settings, :avatar_path, :string
  end

  def self.down
    remove_column :settings, :avatar_path
  end
end
