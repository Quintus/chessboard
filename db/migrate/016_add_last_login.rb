class AddLastLogin < ActiveRecord::Migration
  def self.up
    add_column :users, :last_login, :timestamp
  end

  def self.down
    remove_column :users, :last_login, :timestamp
  end
end
