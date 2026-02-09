class CreateCampaignSends < ActiveRecord::Migration[8.1]
  def change
    create_table :campaign_sends do |t|
      t.references :campaign, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.string :email, null: false
      t.string :status, null: false, limit: 20
      t.datetime :sent_at
      t.text :error_message

      t.timestamps
    end

    add_index :campaign_sends, [ :campaign_id, :contact_id, :created_at ]
    add_index :campaign_sends, :status
  end
end
