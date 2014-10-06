class AddForumIndices < ActiveRecord::Migration
  def self.up
    add_column :forums, :ordernum, :integer, :default => 0
    add_column :forum_groups, :ordernum, :integer, :default => 0
  end

  def self.down
    remove_column :forums, :ordernum
    remove_column :forum_groups, :ordernum
  end
end
