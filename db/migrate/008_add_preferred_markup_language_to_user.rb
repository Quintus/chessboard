class AddPreferredMarkupLanguageToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :preferred_markup_language, :string, :default => Post::DEFAULT_MARKUP_LANGUAGE
  end

  def self.down
    remove_column :users, :preferred_markup_language
  end
end
