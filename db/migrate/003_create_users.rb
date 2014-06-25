class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :nickname
      t.string :realname
      t.string :email
      t.string :homepage
      t.string :rank
      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
