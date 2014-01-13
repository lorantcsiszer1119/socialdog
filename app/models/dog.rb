class Dog < ActiveRecord::Base
  has_and_belongs_to_many :users
  
  validates_presence_of :real_name, :breed, :birthday, :bio
  validates_presence_of :username, :on => :update
  
  def permalink(user)
    return "/#{user.login}/dog/#{self.username}"
  end
  
  def primary_owner
    return User.find(self.first_user_id)
  end
  
  def self.find_by_normalized_username(u)
    Dog.find(:first, :conditions => ['LOWER(username) LIKE ?', u.downcase])
  end
  
  def validate
    # Create username from real_name, then ensure it is unique
    self.username = self.real_name.gsub(/[^a-z0-9]/i, '').downcase
    
    # TODO this needs to check all dogs this user created AND that they're an owner of
    if new_record? || (!new_record? && self.username_changed?)
      uniq_conds = ['LOWER(username) = ? AND first_user_id = ?',
                    self.username, self.first_user_id]
      other_dogs = Dog.find(:all,
                            :conditions => uniq_conds)
      self.errors.add(:username, 'is already taken') unless other_dogs.empty?
    end
    
    # Ensure birthday is a past date
    self.errors.add(:birthday, 'must be today or a date in the past') if birthday > Time.zone.now.to_date
  end
  
  USER_LIMIT    = 3
  BORDER_COLORS = ['e9f1f1', '999c9c', '559cbe',
                   'e0fdff', '87bb05', 'd92b25',
                   'ffc5a5', '99671c'].freeze
  
  has_attached_file :avatar,
                    :default_url => 'http://s3.amazonaws.com/mysocialdog/default_:style.png',
                    :styles      => { :large => '150x150#', :medium => '75x75#', :small => '45x45#', :thumb => '25x25#' },
                    :storage     => :s3,
                                    :s3_credentials => "#{RAILS_ROOT}/config/s3.yml",
                                    :path           => ":class/:attachment/:id/:style.:extension",
                                    :bucket         => S3_BUCKETS[RAILS_ENV]
                                    
                                    
  validates_attachment_presence :avatar
end
