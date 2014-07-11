class CreatePersonalPosts < ActiveRecord::Migration
  def self.up
    create_table :personal_posts do |t|
      t.text :content
      t.string :markup_language
      t.references :author
      t.references :personal_message
      t.timestamps
    end
  end

  def self.down
    drop_table :personal_posts
  end
end
