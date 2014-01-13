class AddFirstUserIdToDog < ActiveRecord::Migration
  def self.up
    add_column :dogs, :first_user_id, :integer
  end

  def self.down
    remove_column :dogs, :first_user_id
  end
end
