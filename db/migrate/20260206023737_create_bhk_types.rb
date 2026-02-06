class CreateBhkTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :bhk_types do |t|
      t.string :name

      t.timestamps
    end
    add_index :bhk_types, :name, unique: true
  end
end
