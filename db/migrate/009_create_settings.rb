class CreateSettings < ActiveRecord::Migration
  def self.up
    remove_column :users, :preferred_markup_language
    create_table :settings do |t|
      t.boolean :hide_status, :default => false
      t.boolean :use_gravatar, :default => false
      t.string :preferred_markup_language, :string, :default => Post::MARKUP_LANGUAGES.first
      t.string :language, :default => "en"
      t.string :time_format, :default => ""
      t.references :user
      t.timestamps
    end
  end

  def self.down
    drop_table :settings
    add_column :users, :preferred_markup_language, :string, :default => Post::MARKUP_LANGUAGES.first
  end
end
