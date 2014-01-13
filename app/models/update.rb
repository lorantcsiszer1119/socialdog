require 'net/http'
require 'uri'

class Update < ActiveRecord::Base
  PER_PAGE = 15
  
  belongs_to :user
  
  validates_presence_of :body
  validates_length_of   :body, :maximum => 140
  
  before_create :stash_lat_lon
  
  def stash_lat_lon
    # Store the creating user's zipcode's lat/lon
    if self.user
      self.lat = self.user.lat
      self.lon = self.user.lon
    else
      # WTF
    end
  end
  
  def self.send_to_3jam(user, message)
    return unless user.mobile_number && user.mobile_domain
    
    u = 'pjzn7JiTLPTd45bMQqE7'
    p = 'VHi9rK6b3LjdqzgB0RQ9'
    sender = '14155131364'
    recip  = user.mobile_number
    
    params = {'username' => u, 'password' => p, 'sender' => sender, 'recip' => recip}
    params['message']     = message
    params['debug_email'] = 'kyle.bragger@gmail.com' if Rails.env.development?
    
    endpoint = 'http://api.3jam.com/sendMsg.php'
    
    # POST
    begin
      
      url = URI.parse(endpoint)
      req = Net::HTTP::Post.new(url.path)
      req.set_form_data(params)
      res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
      
    rescue => e
      # Uh oh.
      raise e if Rails.env.development?
      
    end
    
    return true
  end
  
  def after_create
    # Deliver update notification emails to all users following this user by either email and/or sms
    originating_user = User.find(self.user_id)
    unless originating_user.followers.empty?
      originating_user.followers.each do |follow_user|
        fob = follow_user.find_follow_object_for(originating_user)
        unless fob.nil?
          # By email?
          if fob.by_email?
            Delayed::Job.enqueue EmailJob.new(:follow_update, {:from_user => originating_user.id,
                                                               :to_email  => follow_user.email,
                                                               :format    => 'email',
                                                               :update    => self.id})
          end
          
          # By sms - using 3jam
          if fob.by_sms? && !follow_user.mobile_number.blank? && !follow_user.mobile_domain.blank?
            Update.send_to_3jam(follow_user, "@#{originating_user.login}: #{self.body}")
          end
        end
      end
    end
    
    # Deliver notification email if @ reply user has email prefs set properly
    if is_reply?
      to_user   = User.find_by_normalized_login(self.reply_to_username)
      from_user = User.find(self.user_id)
      if to_user && from_user && to_user.email_at?
        Delayed::Job.enqueue EmailJob.new(:at_reply,
                                          {
                                            :from_user => from_user.id,
                                            :to_user   => to_user.id,
                                            :update_id => self.id
                                          })
      end
    end
  end
  
  def is_reply?
    ((!self.reply_to_username.blank? && !self.reply_to_user_id.blank?) || !self.reply_to_id.blank?)
  end
  
  # pre_process!
  #
  # Returns: false if the update is a regular update, a String (with flash message) if the update is:
  # - a PM
  # - invalid
  #
  def pre_process!(creating_user)
    return false if self.body.blank?
    
    ret = false
    
    # Check for @ reply or PM
    first_char  = self.body[0, 1].downcase
    first_two   = self.body[0, 2].downcase
    username    = self.body.split(' ').first.gsub(/^\@/, '').downcase
    
    if first_char == '@'
      # @ reply
      # If user == self, don't do anything
      if creating_user.login.downcase == username
        # Yep, just return
        ret              = Hash.new
        ret[:flash_type] = :error
        ret[:flash]      = 'You cannot send an @ reply to yourself.'
      else
        # @ reply, so try to find the user
        other_user = User.find_by_normalized_login(username)
        if other_user
          self.reply_to_username = other_user.login
          self.reply_to_user_id  = other_user.id
          self.reply_to_id       = other_user.updates.first.id unless other_user.updates.empty?
        end
      end
    elsif %w{d p}.include?(first_char) && (first_two == 'd ' || first_two == 'p ')
      # PM, so username is actually the second word
      username = self.body.split(' ')[1].gsub(/^\@/, '').downcase
      
      # Create a Private Message instead, then return an appropriate response
      @to_user = User.find_by_normalized_login(username)
      if !@to_user
        ret = {:flash_type => :error, :flash => 'Could not send private message because user was not found.'}
        return ret
      end
      
      fixed_body = self.body.split(' ')
      fixed_body.shift
      fixed_body.shift
      fixed_body = fixed_body.join(' ')
      
      @private_message = PrivateMessage.new({
        :user_id      => creating_user.id,
        :from_user_id => creating_user.id,
        :to_user_id   => @to_user.id,
        :body         => fixed_body
      })
      @private_message.save
      
      ret = {:flash_type => :notice, :flash => "Your private message has been sent to #{@to_user.login}."}
    else
      # Normal update, so just pass through
    end
    
    return ret
  end
end
