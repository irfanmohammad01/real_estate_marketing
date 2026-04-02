class RefreshToken < ApplicationRecord
  belongs_to :authenticatable, polymorphic: true
end
