class AddAddrToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :brand_addr1, :string
    add_column :users, :brand_addr2, :string
    add_column :users, :brand_city, :string
    add_column :users, :brand_state, :string
  end

  def self.down
    remove_column :users, :brand_addr1
    remove_column :users, :brand_addr2
    remove_column :users, :brand_city
    remove_column :users, :brand_state
  end
end
