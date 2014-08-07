class CreateGlobalConfigurations < ActiveRecord::Migration
  def self.up
    create_table :global_configurations do |t|
      t.string :default_time_format, :default => ""
      t.integer :maximum_avatar_dimension, :default => 80
      t.integer :warning_expiration, :default => 60 * 60 * 24 * 365
      t.integer :registration_expiration, :default => 60 * 60 * 24
      t.boolean :registration, :default => true
      t.timestamps
    end
  end

  def self.down
    drop_table :global_configurations
  end
end
