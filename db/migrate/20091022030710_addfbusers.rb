class Addfbusers < ActiveRecord::Migration
  def self.up
    create_table :facebook_users do |t|
      t.integer :user_id
      t.string  :facebook_uid
      t.string  :session_id
      t.string  :auth_token
      t.string  :first_name
      t.string  :last_name
      t.timestamps
    end
  end

  def self.down
    drop_table :facebook_users
  end
end
