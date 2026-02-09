class CreateScheduleTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :schedule_types do |t|
      t.string :name, null: false, limit: 50
      t.timestamps
    end
    add_index :schedule_types, :name, unique: true
  end
end
