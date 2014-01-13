require 'net/http'
require 'uri'

module GoogleGeocoder
  # Only sets lat and lon; does *not* save the record
  def geocode(what)
    logger.info "GoogleGeocoder.geocode!() called => user_id = #{self.id} with payload = #{what}"
    
    # TODO add sanity check for presence of lat and lon attrs
    key = GOOGLE_MAPS_KEYS[RAILS_ENV.to_sym]

    what = CGI.escape(what)
    uri  = "http://maps.google.com/maps/geo?q=#{what}&output=csv&oe=utf8&sensor=false&key=#{key}"
    logger.info "#{what} #{uri}"
    
    # TODO handle timeouts
    res   = Net::HTTP.get_response(URI.parse(uri))
    parts = res.body.split(',')
    if parts.size == 4
      self.lat = parts[2].to_s
      self.lon = parts[3].to_s
    else
      logger.info 'parts.size < 4'
    end
  end
end