class CreateReports < ActiveRecord::Migration
  def self.up
    create_table :reports do |t|
      t.text :description
      t.boolean :closed, :default => false
      t.references :post
      t.references :user
      t.timestamps
    end
  end

  def self.down
    drop_table :reports
  end
end
