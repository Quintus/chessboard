class CreatePosts < ActiveRecord::Migration
  def self.up
    create_table :posts do |t|
      t.text :content
      t.string :language, :default => "Markdown"
      t.integer :edits, :default => 0
      t.timestamps
    end
  end

  def self.down
    drop_table :posts
  end
end
