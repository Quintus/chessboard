class AddReadTopics < ActiveRecord::Migration
  def self.up
    create_table :read_topics, :id => false do |t|
      t.integer :topic_id
      t.integer :user_id
    end
  end

  def self.down
    drop_table :read_topics
  end
end
