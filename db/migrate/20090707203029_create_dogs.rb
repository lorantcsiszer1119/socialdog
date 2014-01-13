class CreateDogs < ActiveRecord::Migration
  def self.up
    create_table :dogs do |t|
      t.string :username
      t.string :real_name
      t.string :breed
      t.text   :bio
      t.date   :birthday
      t.string :border_color
      t.string :avatar_file_name
      t.string :avatar_content_type
      t.string :avatar_file_size
      t.string :avatar_updated_at
      t.timestamps
    end
    
    create_table :dogs_users do |t|
      t.integer :user_id
      t.integer :dog_id
      t.boolean :is_primary, :default => false, :null => false
    end
  end

  def self.down
    drop_table :dogs
    drop_table :dogs_users
  end
end
