class CreateCampaigns < ActiveRecord::Migration[8.1]
  def change
    create_table :campaigns do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :email_template, null: false, foreign_key: true
      t.references :schedule_type, null: false, foreign_key: true
      t.string :name, null: false, limit: 150
      t.string :status, null: false, limit: 20
      t.datetime :scheduled_at
      t.text :cron_expression
      t.datetime :end_date
      t.datetime :last_run_at

      t.timestamps
    end
  end
end
