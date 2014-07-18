class AddPmViews < ActiveRecord::Migration
  def self.up
    add_column :personal_messages, :views, :integer, :default => 0
    create_table :read_pms, :id => false do |t|
      t.integer :user_id
      t.integer :personal_message_id
    end
  end

  def self.down
    drop_table :read_pms
    remove_column :personal_messages, :views
  end
end
