class CreatePowerBackupTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :power_backup_types do |t|
      t.string :name

      t.timestamps
    end
    add_index :power_backup_types, :name, unique: true
  end
end
