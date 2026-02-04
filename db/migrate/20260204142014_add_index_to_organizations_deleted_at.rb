class AddIndexToOrganizationsDeletedAt < ActiveRecord::Migration[8.1]
  def change
    add_index :organizations, :deleted_at
  end
end
