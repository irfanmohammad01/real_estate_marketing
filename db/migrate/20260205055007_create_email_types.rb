class CreateEmailTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :email_types do |t|
      t.string :key
      t.string :description

      t.timestamps
    end
    add_index :email_types, :key, unique: true
  end
end
