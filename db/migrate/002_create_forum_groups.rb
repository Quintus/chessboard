class CreateForumGroups < ActiveRecord::Migration
  def self.up
    create_table :forum_groups do |t|
      t.string :name
      t.timestamps
    end
    add_column :forums, :forum_group_id, :integer
  end

  def self.down
    drop_table :forum_groups
    remove_column :forums, :forum_group_id
  end
end
