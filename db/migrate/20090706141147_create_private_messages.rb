class CreatePrivateMessages < ActiveRecord::Migration
  def self.up
    create_table :private_messages do |t|
      t.integer :user_id
      t.integer :to_user_id
      t.integer :from_user_id
      t.string  :posted_via, :null => false, :default => 'web'
      t.text    :body
      t.timestamps
    end
  end

  def self.down
    drop_table :private_messages
  end
end
