class CreateFollows < ActiveRecord::Migration
  def self.up
    create_table :follows do |t|
      t.integer :user_id
      t.integer :follow_id
      t.boolean :by_email, :null => false, :default => false
      t.boolean :by_sms,   :null => false, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :follows
  end
end
