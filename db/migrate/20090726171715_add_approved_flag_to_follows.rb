class AddApprovedFlagToFollows < ActiveRecord::Migration
  def self.up
    add_column :follows, :approved, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :follows, :approved
  end
end
