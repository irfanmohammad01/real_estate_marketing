class CreateFurnishingTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :furnishing_types do |t|
      t.string :name

      t.timestamps
    end
    add_index :furnishing_types, :name, unique: true
  end
end
