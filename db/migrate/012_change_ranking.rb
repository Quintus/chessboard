class ChangeRanking < ActiveRecord::Migration
  def self.up
    remove_column :users, :rank
  end

  def self.down
    add_column :users, :rank, :string
  end
end
