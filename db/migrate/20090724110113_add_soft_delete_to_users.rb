class AddSoftDeleteToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :deleted_at, :datetime, :null => true
  end

  def self.down
    remove_column :users, :deleted_at
  end
end
