class ViewedEpisode < ApplicationRecord
  belongs_to :user
  belongs_to :subscription
  validates_uniqueness_of :episode_id, scope: :user_id
  before_create :set_status


  private

  def set_status
    self.viewed = true
  end

end
