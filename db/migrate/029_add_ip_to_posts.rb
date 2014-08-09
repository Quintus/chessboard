class AddIpToPosts < ActiveRecord::Migration
  def self.up
    add_column :posts, :ip, :string
  end

  def self.down
    remove_column :posts, :ip
  end
end
