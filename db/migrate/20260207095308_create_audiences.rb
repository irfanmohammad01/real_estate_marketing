class CreateAudiences < ActiveRecord::Migration[8.1]
  def change
    create_table :audiences do |t|
      t.integer :organization_id
      t.string :name
      t.integer :bhk_type_id
      t.integer :furnishing_type_id
      t.integer :location_id
      t.integer :property_type_id
      t.integer :power_backup_type_id

      t.timestamps
    end

    add_index :audiences, :organization_id
  end
end
