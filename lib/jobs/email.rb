class EmailJob < Struct.new(:method, :args)
  def perform
    begin

      case method
      when :at_reply
        to_user   = User.find(args[:to_user])
        from_user = User.find(args[:from_user])
        update    = Update.find(args[:update_id])
        Notifier.deliver_at_reply(from_user, to_user, update)
      
      when :follow
        current_user  = User.find(args[:from_user])
        followed_user = User.find(args[:to_user])
        Notifier.deliver_follow(current_user, followed_user)
      
      when :friend_request
        current_user  = User.find(args[:from_user])
        followed_user = User.find(args[:to_user])
        Notifier.deliver_friend_request(current_user, followed_user)
      
      when :pm
        to_user   = User.find(args[:to_user])
        from_user = User.find(args[:from_user])
        pm        = PrivateMessage.find(args[:pm])
        Notifier.deliver_private_message(from_user, to_user, pm)
      
      when :pm_sms
        to_user   = User.find(args[:to_user])
        from_user = User.find(args[:from_user])
        pm        = PrivateMessage.find(args[:pm])
        Update.send_to_3jam(to_user, "Private msg from @#{from_user.login}: #{pm.body} / Reply on the web at http://www.mysocialdog.com")
   
      when :welcome
        user = User.find(args[:user_id])
        Notifier.deliver_welcome(user)
   
      when :invite
        from_user = User.find(args[:from])
        msg       = args[:msg] || nil
        Notifier.deliver_invite(from_user, args[:to], msg)
      
      when :follow_update
        originating_user = User.find(args[:from_user])
        update           = Update.find(args[:update])
        Notifier.deliver_follow_update(originating_user, args[:to_email], args[:format], update)
      
      end
    
    rescue => e
      
      
    
    end # begin
    
  end
end