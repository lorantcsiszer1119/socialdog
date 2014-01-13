class CreateUpdates < ActiveRecord::Migration
  def self.up
    create_table :updates do |t|
      t.integer :user_id
      t.string  :posted_via, :null => false, :default => 'web'
      t.text    :body
      t.integer :reply_to_id
      t.integer :reply_to_user_id
      t.string  :reply_to_username
      t.timestamps
    end
  end

  def self.down
    drop_table :updates
  end
end
