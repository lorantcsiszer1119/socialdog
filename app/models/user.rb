require 'paperclip'

class User < ActiveRecord::Base
  ADMIN_USERS = ['kyle', 'adam', 'sharon'].freeze
  
  MAILCHIMP_API_KEY = '5c2c667b6b33790a1f63082dee0602c7'
  
  has_many :updates, :order => 'created_at DESC'
  has_and_belongs_to_many :dogs
  has_many :invites, :order => 'created_at DESC'
  has_many :point_awards, :order => 'created_at DESC'
  
  before_save :before_save_for_zipcode
  
  def zipcode_metadata
    Zipcode.find_by_strict_type_cast(self.zipcode)
  end
  
  def before_save_for_zipcode
    # Create a Zipcode if none exists
    if !Zipcode.find_by_strict_type_cast(self.zipcode)
      Zipcode.create(:zipcode => self.zipcode) # This also will kick off the geocoding
    end
    
    # Stash the lat/lon
    if self.lat.blank? && self.lon.blank?
      zc = zipcode_metadata
      self.lat = zc.lat unless zc.lat.blank?
      self.lon = zc.lon unless zc.lon.blank?
    end
  end
  
  def after_create
    # Invite stuff
    Invite.find(:all, :conditions => ['email = ? AND used = false', self.email]).each do |inv|
      inv.update_attributes(:used            => true,
                            :used_at         => Time.zone.now,
                            :login           => self.login,
                            :invited_user_id => self.id)
    end
  end
  
  def before_save
    # Mailchimp
    @hominid = Hominid.new({:username     => 'mysocialdog',
                            :password     => 'mysocialchimp',
                            :api_key      => MAILCHIMP_API_KEY,
                            :send_goodbye => false,
                            :send_notify  => false,
                            :double_opt   => false})
    sub = false
    sub = true if (!self.new_record? && self.email_news_changed? && self.email_news?)
    sub = true if (self.new_record? && self.email_news?)
    
    if sub
      logger.info "chimp for user id #{self.id} -> #{self.email_news?} sub"
      @hominid.subscribe(86044,
                        self.email,
                        {:FNAME => self.real_name.split(' ').first, :LNAME => self.real_name.split(' ').last},
                        'html')
    elsif (self.email_news_changed? && !self.email_news?)
      logger.info "chimp for user id #{self.id} -> #{self.email_news?} unsub"
      @hominid.unsubscribe(86044, self.email)
    end
    
    true
  end
  
  def after_destroy
    if self.email_news?
      @hominid = Hominid.new({:username     => 'mysocialdog',
                              :password     => 'mysocialchimp',
                              :api_key      => MAILCHIMP_API_KEY,
                              :send_goodbye => false,
                              :send_notify  => false,
                              :double_opt   => false})
                              
      @hominid.unsubscribe(86044, self.email)
    end
    
    # Remove follows
    Follow.destroy_all(['user_id = ? OR follow_id = ?', self.id, self.id])
  end
  
  def followers
    f   = Follow.find_all_by_follow_id(self.id)
    ids = f.collect(&:user_id).uniq
    return [] if ids.empty?
    User.find(ids)
  end
  
  def follows
    f   = Follow.find_all_by_user_id_and_approved(self.id, true)
    ids = f.collect(&:follow_id).uniq
    return [] if ids.empty?
    User.find(ids, :order => 'bio ASC')
  end
  
  has_attached_file :avatar,
                    :default_url => 'http://s3.amazonaws.com/mysocialdog/default_:style.png',
                    :styles      => { :large => '150x150#', :medium => '75x75#', :small => '45x45#', :thumb => '25x25#' },
                    :storage     => :s3,
                                    :s3_credentials => "#{RAILS_ROOT}/config/s3.yml",
                                    :path           => ":class/:attachment/:id/:style.:extension",
                                    :bucket         => S3_BUCKETS[RAILS_ENV]
  
  
  has_attached_file :logo,
                    :default_url => 'http://s3.amazonaws.com/mysocialdog/default_brand_:style.png',
                    :styles      => { :large => '150x150#', :medium => '75x75#', :small => '45x45#', :thumb => '25x25#' },
                    :storage     => :s3,
                                    :s3_credentials => "#{RAILS_ROOT}/config/s3.yml",
                                    :path           => ":class/:attachment/:id/:style.:extension",
                                    :bucket         => S3_BUCKETS[RAILS_ENV]
  
  # FIXME perishable_token re-saving a user record calls this, and we get failed validations even when not doing
  # a save explicitly
  validates_attachment_presence :logo, :if => Proc.new {|u| u.is_brand?}, :on => :update
  
  MOBILE_DOMAINS = {
    'Alltel'            => 'message.alltel.com',
    'AT&T'              => 'txt.att.net',
    'Boost Mobile'      => 'myboostmobile.com',
    'Nextel'            => 'messaging.nextel.com',
    'Sprint'            => 'messaging.sprintpcs.com',
    'T-Mobile'          => 'tmomail.net',
    'Verizon'           => 'vtext.com',
    'Virgin Mobile USA' => 'vmobl.com'
  }.freeze
  
  RESERVED_LOGINS = ['district_dog', 'districtdog', 'cron', 'crons', 'search', 'tag', 'tags',
                     'brands', 'brand', 'dog', 'dogs', 'kylebragger', 'kb', 'kyle', 'adam', 'sharon',
                     'socialdog', 'dog', 'petco', 'purina', 'account', 'www', 'admin', 'users', 'static',
                     'site', 'settings', 'login', 'logout', 'signup', 'follow', 'follows', 'update',
                     'updates', 'home', 'everyone', 'friends', 'page', 'pages', 'replies', 'reply',
                     'private', 'private_messages', 'direct', 'direct_messages', 'message', 'messages',
                     'invite', 'search', 'mysocialdog', 'adamhirsch', 'sharonfeder', 'mashbark',
                     'mashable', 'iams', 'beneful', 'purina', 'pedigree', 'hillspet', 'candiae', 'petsmart',
                     'jbpet', 'nutro', 'petco', 'petmarket', 'sciencediet', 'petstore', 'biscuitsandbath',
                     'barkingdog', 'furrypaws', 'petcarerx', 'petmeds', '1800petmeds', 'drsfostersmith',
                     'petstoreonline', 'fuzzster', 'dogster', 'dognamic', 'dogpark', 'ecoanimal', 'dogparkusa',
                     'dogmeet', 'uniteddogs', 'dogsturst', 'neighbor', 'neighbors', 'hash', 'hashtag', 'hashtags'].freeze
  
  LOGIN_REGEXP = /([^a-z0-9])+/i
  
  acts_as_authentic do |c|
    # Interesting that authlogic is doing case-sensitive email/login validation...
    c.validates_format_of_login_field_options = {
      :with     => /([a-z0-9])/i,
      :message  => I18n.t('error_messages.login_invalid', :default => "should use only letters and numbers please.")
    }
  end
  
  validates_numericality_of :mobile_number, :on => :update, :unless => Proc.new { |m| m.is_brand? || m.mobile_number.blank? },
                                                            :message => 'must be a 10 digit number, no dashes or spaces'
  validates_format_of       :mobile_number, :on => :update, :with => /^\d{10}$/, :message => "isn't valid",
                                                            :unless => Proc.new { |m| m.is_brand? || m.mobile_number.blank? }
  validates_presence_of     :mobile_domain, :on => :update, :unless => Proc.new { |m| m.is_brand? || m.mobile_number.blank? }
  validates_format_of       :zipcode, :with => /^\d{5}$/, :message => "isn't valid (must be 5 digits)"
  validates_presence_of     :real_name
  
  validates_length_of :brand_special_message, :maximum => 140, :if => Proc.new{|u| u.is_brand?}, :on => :update
  validates_length_of :brand_bio,             :maximum => 400, :if => Proc.new{|u| u.is_brand?}, :on => :update
  validates_format_of :brand_website,         :with => /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix,
                                              :if => Proc.new{|u| u.is_brand?}, :on => :update,
                                              :message => 'must be in the format http://mywebsite.com'
  
  def validate
    # Login reserved?
    if new_record? || login_changed?
      self.errors.add(:login, 'is reserved. If you believe this username belongs to you, please email contact support@mysocialdog.com') if RESERVED_LOGINS.include?(login.downcase)
    end
    
    # Login format
    if new_record?
      self.errors.add(:login, 'should use only letters and numbers please.') if login =~ LOGIN_REGEXP
    end
  end
  
  validates_field :bio do |of|
    of.presence :on => :update
    of.length   :on => :update, :maximum => 140
  end
  
  def self.find_by_smart_case_login_field(login)
    find(:first, :conditions => ['LOWER(email) = ? OR LOWER(login) = ?', login.downcase, login.downcase])
  end
  
  # Finds a single user by a downcased login (to prevent weirdness with mysql <-> postgres)
  def self.find_by_normalized_login(login)
    User.find(:first, :conditions => ['LOWER(login) LIKE ?', login.downcase])
  end
  
  has_one :twitter_user
  has_one :facebook_user
  
  def facebook_linked?
    unless self.facebook_user.nil?
      return true
    else
      # FB Connect user?
      return !!facebook_connect_user?
    end
  end
  
  def facebook_connect_user?
    return !fb_user_id.nil? && fb_user_id > 0
  end
  
  def self.find_by_fb_user(fb_user)
    User.find_by_fb_user_id(fb_user.uid) || User.find_by_email_hash(fb_user.email_hashes)
  end
  
  def self.create_from_fb_connect(fb_user)
    return false if fb_user.first_name.blank? || fb_user.last_name.blank?
    new_facebooker = User.new({
      :first_name  => fb_user.first_name,
      :last_name   => fb_user.last_name,
      :screen_name => "user#{Digest::SHA1.hexdigest(fb_user.uid.to_s)[0,10]}",
      :password    => "",
      :email       => "",
      :tos         => true,
      :status      => true
    })
    new_facebooker.fb_user_id = fb_user.uid.to_i
    # We need to save without validations
    new_facebooker.save(false)
    new_facebooker.register_user_to_fb
  end
  
  def link_fb_connect(fb_user_id)
    unless fb_user_id.nil?
      #check for existing account
      existing_fb_user = User.find_by_fb_user_id(fb_user_id)
      #unlink the existing account
      unless existing_fb_user.nil?
        existing_fb_user.fb_user_id = nil
        existing_fb_user.save(false)
      end
      #link the new one
      self.fb_user_id = fb_user_id
      save(false)
    end
  end
  
  def register_user_to_fb
    users = {:email => email, :account_id => id}
    Facebooker::User.register([users])
    self.email_hash = Facebooker::User.hash_email(email)
    save(false)
  end
  
  def facebook_user?
    return !fb_user_id.nil? && fb_user_id > 0
  end
  
  def twitter_linked?
    self.twitter_user.nil? ? false : true
  end
  
  def follow!(user)
    return false if is_following?(user)
    Follow.create(:user_id => self.id, :follow_id => user.id, :approved => !user.private?).save unless user.id == self.id
    return true
  end
  
  def unfollow!(user)
    return false unless is_following?(user)
    self.find_follow_object_for(user).destroy unless user.id == self.id
    return true
  end
  
  def is_following?(user)
    return self.follows.collect(&:id).include?(user.id) ? true : false
  end
  
  def follow_pending?(user)
    return Follow.find_by_user_id_and_follow_id_and_approved(self.id, user.id, false) ? true : false
  end
  
  def follow_requests
    Follow.find_all_by_follow_id_and_approved(self.id, false)
  end
  
  def find_follow_object_for(user)
    return Follow.find_by_user_id_and_follow_id(self.id, user.id)
  end
  
  def deliver_password_reset_instructions!  
    reset_perishable_token!  
    Notifier.deliver_password_reset_instructions(self)  
  end
  
  def owner_of?(dog)
    dog.users.exists?(self.id)
  end
  
  def admin?
    ADMIN_USERS.include?(self.login.downcase)
  end
end
