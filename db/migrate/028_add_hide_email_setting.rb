class AddHideEmailSetting < ActiveRecord::Migration
  def self.up
    add_column :settings, :hide_email, :boolean, :default => true
  end

  def self.down
    remove_column :settings, :hide_email
  end
end
