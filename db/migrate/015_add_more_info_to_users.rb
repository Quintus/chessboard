class AddMoreInfoToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :location, :string
    add_column :users, :profession, :string
    add_column :users, :jabber_id, :string
    add_column :users, :pgp_key, :string
  end

  def self.down
    remove_column :users, :location
    remove_column :users, :profession
    remove_column :users, :jabber_id
    remove_column :users, :pgp_key
  end
end
