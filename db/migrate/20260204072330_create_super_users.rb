class CreateSuperUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :super_users do |t|
      t.string :email
      t.string :password_digest

      t.timestamps
    end
  end
end
