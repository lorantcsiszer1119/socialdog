ActiveRecord::Schema.define(:version => 1) do
  create_table :friends, :force => true do |t|
    t.column :name, :string
    t.column :age,  :integer
    t.column :bio,  :string
  end
end