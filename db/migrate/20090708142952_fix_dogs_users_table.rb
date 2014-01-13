class FixDogsUsersTable < ActiveRecord::Migration
  def self.up
    remove_column :dogs_users, :id
    remove_column :dogs_users, :is_primary
  end

  def self.down
    add_column :dogs_users, :id, :integer
    add_column :dogs_users, :is_primary, :boolean, :null => false, :default => false
  end
end
