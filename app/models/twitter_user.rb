require 'net/http'
 
class TwitterUser < ActiveRecord::Base
  include TwitterAuth
  
  belongs_to :user
  
  # Post a new tweet to Twitter and return either the tweet id on success, or false on failure
  def post_update(text)
    
    access_token = token
    resp = access_token.post('/statuses/update.json', :status => text)
    case resp
    when Net::HTTPSuccess
      json = JSON.parse(resp.body)
      return json['id'].to_i
    else
      # We should return a more detailed response probably...
      return false
    end
  end
  
  def self.identify_or_create_by_access_token(user, token, secret = nil)
    path_prefix = URI.parse(TwitterAuth.config['base_url']).path
    
    token = OAuth::AccessToken.new(TwitterUsersController.consumer, token, secret) unless token.is_a?(OAuth::AccessToken)
    resp  = token.get(path_prefix + '/account/verify_credentials.json')
    
    case resp
    when Net::HTTPSuccess
      
      @twitter_user = find_or_create_by_user_id(user.id)
      user_info = JSON.parse(resp.body)
      
      # Update user with fresh info from twitter
      attributes = {}
      user_info.each do |k,v|
        attributes[k] = v if @twitter_user.has_attribute?(k)
      end
      
      # OAuth token/secret
      attributes['access_token']  = token.token
      attributes['access_secret'] = token.secret
      
      # Clear timestamps
      attributes.delete('created_at')
      attributes.delete('updated_at')
      
      # user id and login
      attributes['twitter_id'] = user_info['id']
      attributes['login']      = user_info['screen_name']
      
      @twitter_user.update_attributes(attributes) unless attributes.empty?
      
    end
    
    return @twitter_user
  end
  
  def token
    OAuth::AccessToken.new(TwitterUsersController.consumer, self.access_token, self.access_secret) if (self.access_token && self.access_secret)
  end
end