class CreateCampaignAudiences < ActiveRecord::Migration[8.1]
  def change
    create_table :campaign_audiences do |t|
      t.integer :campaign_id
      t.integer :audience_id

      t.timestamps
    end
    add_index :campaign_audiences, [ :campaign_id, :audience_id ], unique: true
  end
end
