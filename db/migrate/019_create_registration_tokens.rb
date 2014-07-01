class CreateRegistrationTokens < ActiveRecord::Migration
  def self.up
    create_table :registration_tokens do |t|
      t.datetime :expiration_date
      t.string :encrypted_tokenstr, :string
      t.references :user
      t.timestamps
    end
    add_column :users, :confirmed, :boolean, :default => false
  end

  def self.down
    drop_table :registration_tokens
    remove_column :users, :confirmed
  end
end
