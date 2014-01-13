class AwardEarlyAdopterPoints < ActiveRecord::Migration
  def self.up
    User.all.each do |user|
      puts "awarding #{user.id}..."
      user.point_awards.create(:context => 'early_adopter', :value => 25)
    end
  end

  def self.down
  end
end
