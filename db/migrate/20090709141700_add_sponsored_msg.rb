class AddSponsoredMsg < ActiveRecord::Migration
  def self.up
    add_column :updates, :is_sponsored, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :updates, :is_sponsored
  end
end
