class AddModeration < ActiveRecord::Migration
  def self.up
    create_table :moderation, :id => false do |t|
      t.integer :user_id
      t.integer :forum_id
    end
    add_column :users, :admin, :boolean, :default => false
  end

  def self.down
    drop_table :moderation
    remove_column :users, :admin
  end
end
