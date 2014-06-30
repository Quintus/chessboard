class CreateWarnings < ActiveRecord::Migration
  def self.up
    create_table :warnings do |t|
      t.text :reason
      t.integer :warned_user_id
      t.integer :warning_user_id
      t.datetime :expiration_date
      t.timestamps
    end
  end

  def self.down
    drop_table :warnings
  end
end
