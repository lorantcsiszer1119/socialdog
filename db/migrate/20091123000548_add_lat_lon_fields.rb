class AddLatLonFields < ActiveRecord::Migration
  def self.up
    add_column :users, :lat, :string
    add_column :users, :lon, :string
    add_column :updates, :lat, :string
    add_column :updates, :lon, :string
  end

  def self.down
    remove_column :users, :lat
    remove_column :users, :lon
    remove_column :updates, :lat
    remove_column :updates, :lon
  end
end
