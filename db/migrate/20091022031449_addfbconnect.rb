class Addfbconnect < ActiveRecord::Migration
  def self.up
    add_column :users, :fb_user_id, :integer
    add_column :users, :email_hash, :string
    # TODO
    #execute("ALTER TABLE users MODIFY fb_user_id bigint")
  end

  def self.down
    remove_column :users, :fb_user_id
    remove_column :users, :email_hash
  end
end
