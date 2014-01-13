# Would love to do:
# PointAward.award! current_user, :for_first_follower #=> AWARD_TYPES = {:for_first_follower => 1} # value = 1
class PointAward < ActiveRecord::Base
  belongs_to :user
  
  after_create :update_user_cache
  
  private
  
  def update_user_cache
    self.user.update_attribute(:points, self.user.points.to_i + self.value)
  end
end
