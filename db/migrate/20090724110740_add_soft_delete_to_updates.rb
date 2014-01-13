class AddSoftDeleteToUpdates < ActiveRecord::Migration
  def self.up
    add_column :updates, :deleted_at, :datetime, :null => true
  end

  def self.down
    remove_column :updates, :deleted_at
  end
end
