class CreateContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :contacts do |t|
      t.integer :organization_id
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone

      t.timestamps
    end
  end
end
