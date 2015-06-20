class CreateModerations < ActiveRecord::Migration
  def self.up
    create_table :moderations do |t|
      t.references :moderator
      t.references :targetted_user
      t.references :post
      t.string :action
      t.timestamps :null => false
    end
  end

  def self.down
    drop_table :moderations
  end
end
