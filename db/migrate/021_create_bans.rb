class CreateBans < ActiveRecord::Migration
  def self.up
    create_table :bans do |t|
      t.string :nick_pattern
      t.string :email_pattern
      t.string :ip_range
      t.text :reason
      t.datetime :expiration_date
      t.timestamps
    end
  end

  def self.down
    drop_table :bans
  end
end
