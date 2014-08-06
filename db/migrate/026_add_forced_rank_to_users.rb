class AddForcedRankToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :forced_rank, :string
  end

  def self.down
    remove_column :users, :forced_rank
  end
end
