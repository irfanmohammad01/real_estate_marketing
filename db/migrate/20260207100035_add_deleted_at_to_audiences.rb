class AddDeletedAtToAudiences < ActiveRecord::Migration[8.1]
  def change
    add_column :audiences, :deleted_at, :datetime
    add_index :audiences, :deleted_at
  end
end
