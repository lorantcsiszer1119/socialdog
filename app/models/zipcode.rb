# PI = 3.1415926535  
RAD_PER_DEG = 0.017453293  #  PI/180  
  
# the great circle distance d will be in whatever units R is in  
  
Rmiles = 3956           # radius of the great circle in miles  
Rkm = 6371              # radius in kilometers...some algorithms use 6367  
Rfeet = Rmiles * 5282   # radius in feet  
Rmeters = Rkm * 1000    # radius in meters  
  
#@distances = Hash.new   # this is global because if computing lots of track point distances, it didn't make  
                        # sense to new a Hash each time over potentially 100's of thousands of points  
  
=begin rdoc  
  given two lat/lon points, compute the distance between the two points using the haversine formula  
  the result will be a Hash of distances which are key'd by 'mi','km','ft', and 'm'  
=end  
  
class Zipcode < ActiveRecord::Base
  include GoogleGeocoder
  
  def self.find_by_strict_type_cast(zipcode)
    find(:first, :conditions => ['zipcode = ?', zipcode.to_s])
  end
  
  def before_create
    self.geocode(self.zipcode)
  end
  
  def haversine_distance( lat1, lon1, lat2, lon2 )  

    logger.info "haversine_distance() #{lat1} #{lon1} #{lat2} #{lon2}"
    
    dlon = lon2 - lon1  
    dlat = lat2 - lat1  

    dlon_rad = dlon * RAD_PER_DEG   
    dlat_rad = dlat * RAD_PER_DEG  

    lat1_rad = lat1 * RAD_PER_DEG  
    lon1_rad = lon1 * RAD_PER_DEG  

    lat2_rad = lat2 * RAD_PER_DEG  
    lon2_rad = lon2 * RAD_PER_DEG  

    # puts "dlon: #{dlon}, dlon_rad: #{dlon_rad}, dlat: #{dlat}, dlat_rad: #{dlat_rad}"  

    a = (Math.sin(dlat_rad/2))**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * (Math.sin(dlon_rad/2))**2  
    c = 2 * Math.atan2( Math.sqrt(a), Math.sqrt(1-a))  

    dMi = Rmiles * c          # delta between the two points in miles  
    dKm = Rkm * c             # delta in kilometers  
    dFeet = Rfeet * c         # delta in feet  
    dMeters = Rmeters * c     # delta in meters  

    @distances = {}

    @distances["mi"] = dMi  
    @distances["km"] = dKm  
    @distances["ft"] = dFeet  
    @distances["m"] = dMeters  

    return @distances
  end
end
