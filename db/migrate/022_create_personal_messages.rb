class CreatePersonalMessages < ActiveRecord::Migration
  def self.up
    create_table :personal_messages do |t|
      t.string :title
      t.references :author
      t.timestamps
    end
  end

  def self.down
    drop_table :personal_messages
  end
end
