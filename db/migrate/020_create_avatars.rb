class CreateAvatars < ActiveRecord::Migration
  def self.up
    remove_column :settings, :avatar_path
    create_table :avatars do |t|
      t.string :path
      t.references :user
      t.timestamps
    end
  end

  def self.down
    drop_table :avatars
    add_column :settings, :avatar_path, :string
  end
end
