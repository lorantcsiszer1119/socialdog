class AddFieldsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :mobile_number, :string
    add_column :users, :mobile_domain, :string
  end

  def self.down
    remove_column :users, :mobile_number
    remove_column :users, :mobile_domain
  end
end
