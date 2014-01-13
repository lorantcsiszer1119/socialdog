class CreateInvites < ActiveRecord::Migration
  def self.up
    create_table :invites do |t|
      t.integer  :user_id
      t.integer  :invited_user_id
      t.boolean  :used, :default => false, :null => false
      t.datetime :used_at
      t.text     :message
      t.string   :guid
      t.string   :login
      t.string   :email
      t.timestamps
    end
  end

  def self.down
    drop_table :invites
  end
end
