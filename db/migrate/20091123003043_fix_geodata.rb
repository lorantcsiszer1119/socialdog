class FixGeodata < ActiveRecord::Migration
  def self.up
    User.all.each do |user|
      begin
        # User
        zm = user.zipcode_metadata
        puts zm.inspect
        user.lat = zm.lat
        user.lon = zm.lon
        user.save(false)
        user2 = User.find(user.id)
        puts "id=#{user2.id} #{user2.lat} #{user2.lon}"
      
        # Now updates
        user2.updates.each do |up|
          up.lat = user2.lat
          up.lon = user2.lon
          up.save(false)
          puts "up id=#{up.id} #{up.lat} #{up.lon}"
        end
      rescue => e
        puts "userid #{user.id}, exception: #{e.to_s}"
      end
    end
  end

  def self.down
  end
end
