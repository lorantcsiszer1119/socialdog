class AddBrandFields < ActiveRecord::Migration
  def self.up
    add_column :users, :is_brand,          :boolean, :null => false, :default => false
    add_column :users, :logo_file_name,    :string
    add_column :users, :logo_content_type, :string
    add_column :users, :logo_file_size,    :integer
    add_column :users, :logo_updated_at,   :datetime
    add_column :users, :brand_bio,         :text
    add_column :users, :brand_special_message, :text
    add_column :users, :brand_website,     :string
  end

  def self.down
    remove_column :users, :is_brand
    remove_column :users, :logo_file_name
    remove_column :users, :logo_content_type
    remove_column :users, :logo_file_size
    remove_column :users, :logo_updated_at
    remove_column :users, :brand_bio
    remove_column :users, :brand_special_message
    remove_column :users, :brand_website
  end
end
