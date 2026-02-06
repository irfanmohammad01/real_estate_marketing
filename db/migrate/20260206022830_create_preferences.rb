class CreatePreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :preferences do |t|
      t.integer :contact_id
      t.integer :bhk_type_id
      t.integer :furnishing_type_id
      t.integer :location_id
      t.integer :property_type_id
      t.integer :power_backup_type_id

      t.timestamps
    end
  end
end
