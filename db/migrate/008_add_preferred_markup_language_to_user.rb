class AddPreferredMarkupLanguageToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :preferred_markup_language, :string, :default => Post::MARKUP_LANGUAGES.first
  end

  def self.down
    remove_column :users, :preferred_markup_language
  end
end
