class CreateCampaigns < ActiveRecord::Migration[8.1]
  def change
    create_table :campaigns do |t|
      t.integer :organization_id
      t.integer :email_template_id
      t.string :status
      t.string :name
      t.integer :schedule_type_id
      t.datetime :scheduled_at
      t.text :cron_expression
      t.datetime :end_date
      t.datetime :last_run_at

      t.timestamps
    end
  end
end
