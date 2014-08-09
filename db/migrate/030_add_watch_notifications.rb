class AddWatchNotifications < ActiveRecord::Migration
  def self.up
    add_column :settings, :auto_watch, :boolean, :default => false
    create_table :watchers, :id => false do |t|
      t.integer :topic_id
      t.integer :user_id
    end
  end

  def self.down
    remove_column :settings, :auto_watch
    drop_table :watchers
  end
end
