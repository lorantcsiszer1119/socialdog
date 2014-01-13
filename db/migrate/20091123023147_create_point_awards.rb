class CreatePointAwards < ActiveRecord::Migration
  def self.up
    create_table :point_awards do |t|
      t.string     :context
      t.integer    :value
      t.references :user
      t.timestamps
    end
    
    add_column :users, :points, :integer, :default => 0
  end

  def self.down
    drop_table :point_awards
    remove_column :users, :points
  end
end
