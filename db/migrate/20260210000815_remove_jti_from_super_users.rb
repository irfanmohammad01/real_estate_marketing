class RemoveJtiFromSuperUsers < ActiveRecord::Migration[8.1]
  def change
    remove_index :super_users, :jti if index_exists?(:super_users, :jti)
    remove_column :super_users, :jti, :string
  end
end
