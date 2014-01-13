require 'net/http'

class FacebookUser < ActiveRecord::Base
  belongs_to :user
  
  def post_update(text)
    return FacebookAuth.publish_stream(self, text)
  end
end
