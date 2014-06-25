class CreateTopics < ActiveRecord::Migration
  def self.up
    create_table :topics do |t|
      t.string :title
      t.boolean :sticky, :default => false
      t.boolean :announcement, :default => false
      t.boolean :locked, :default => false
      t.references :forum
      t.integer :author_id
      t.timestamps
    end
    add_column :posts, :topic_id, :integer
    add_column :posts, :author_id, :integer
  end

  def self.down
    drop_table :topics
    remove_column :posts, :topic_id
    remove_column :posts, :author_id
  end
end
