class AddPmAccessRestrictions < ActiveRecord::Migration
  def self.up
    create_table :pm_access, :id => false do |t|
      t.integer :user_id
      t.integer :personal_message_id
    end
  end

  def self.down
    drop_table :pm_access
  end
end
