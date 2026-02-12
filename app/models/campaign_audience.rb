class CampaignAudience < ApplicationRecord
  belongs_to :campaign
  belongs_to :audience

  validates :campaign_id, presence: true
  validates :audience_id, presence: true
  validates :audience_id, uniqueness: { scope: :campaign_id, message: "already added to this campaign" }
end
