class MakeSignatureText < ActiveRecord::Migration
  def self.up
    remove_column :users, :signature
    add_column :users, :signature, :text
  end

  def self.down
    remove_column :users, :signature
    add_column :users, :signature, :string
  end
end
