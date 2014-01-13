class Notifier < ActionMailer::Base
  default_url_options[:host] = "www.mysocialdog.com"  

  helper :updates

  def password_reset_instructions(user)  
    subject       "[My Social Dog] Password Reset Instructions"  
    from          "no-reply@mysocialdog.com"  
    recipients    user.email  
    sent_on       Time.now  
    body          :edit_password_reset_url => edit_password_reset_url(user.perishable_token)  
  end
  
  def private_message(from_user, to_user, pm)
    subject     "[My Social Dog] New private message from #{from_user.login}"
    from        "no-reply@mysocialdog.com"  
    recipients  to_user.email
    sent_on     Time.now
    body        :from_user => from_user, :to_user => to_user, :pm => pm
  end
  
  def private_message_sms(from_user, to_user, pm)
    subject     'My Social Dog'
    from        "no-reply@mysocialdog.com"  
    recipients  "#{to_user.mobile_number}@#{to_user.mobile_domain}"
    sent_on     Time.now
    body        :from_user => from_user, :to_user => to_user, :pm => pm
  end
  
  def follow_update(from_user, to_email, format, update)
    subject     format == 'email' ? "[My Social Dog] New update from #{from_user.login}" : 'My Social Dog'
    from        "no-reply@mysocialdog.com"  
    recipients  to_email
    sent_on     Time.now
    body        :from_user => from_user, :update => update, :format => format
  end
  
  def at_reply(from_user, to_user, update)
    subject     "[My Social Dog] New reply from #{from_user.login}"
    from        "no-reply@mysocialdog.com"  
    recipients  to_user.email
    sent_on     Time.now
    body        :from_user => from_user, :to_user => to_user, :update => update
  end
  
  def follow(from_user, to_user)
    subject     "[My Social Dog] #{from_user.login} is now following you!"
    from        "no-reply@mysocialdog.com"  
    recipients  to_user.email
    sent_on     Time.now
    body        :from_user => from_user, :to_user => to_user
  end
  
  def friend_request(from_user, to_user)
    subject     "[My Social Dog] #{from_user.login} has requested to follow you"
    from        "no-reply@mysocialdog.com"  
    recipients  to_user.email
    sent_on     Time.now
    body        :from_user => from_user, :to_user => to_user
  end
  
  def welcome(user)
    subject     "[My Social Dog] Welcome to My Social Dog!"
    from        "no-reply@mysocialdog.com"
    recipients  user.email
    sent_on     Time.now
    body        :user => user
  end
  
  def invite(from_user, to_email, msg)
    subject     "[My Social Dog] #{from_user.login} (#{from_user.real_name}) has invited you to join My Social Dog"
    from        "no-reply@mysocialdog.com"
    recipients  to_email
    sent_on     Time.now
    body        :from_user => from_user, :message => msg
  end
end
