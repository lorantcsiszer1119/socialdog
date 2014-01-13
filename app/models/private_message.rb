class PrivateMessage < ActiveRecord::Base
  PER_PAGE = 2
  
  def user(which = 'to')
    if which == 'to'
      User.find(self.from_user_id)
    else
      User.find(self.to_user_id)
    end
  end
  
  def after_create
    # Send email
    to_user = User.find(self.to_user_id)
    Delayed::Job.enqueue EmailJob.new(:pm,
                                      {
                                        :from_user => self.from_user_id,
                                        :to_user   => self.to_user_id,
                                        :pm        => self.id
                                      }) if to_user.email_pm?
                                      
    # Send SMS if user is set up for it
    unless to_user.mobile_domain.blank? || to_user.mobile_number.blank?
      Delayed::Job.enqueue EmailJob.new(:pm_sms,
                                        {
                                          :from_user => self.from_user_id,
                                          :to_user   => self.to_user_id,
                                          :pm        => self.id
                                        }) if to_user.email_pm?
    end
  end
end
