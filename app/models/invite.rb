class Invite < ActiveRecord::Base
  belongs_to :invited_user, :class_name => 'User', :foreign_key => 'invited_user_id'
  
  DEFAULT_MESSAGE = <<-MSG
Hi! {login} ({real_name}) has invited you to join My Social Dog.

  {message}

You can sign up here:

http://www.mysocialdog.com/signup?follow={login} (once you do, you'll automatically start following {login})

Check out their profile here:

http://www.mysocialdog.com/{login}

Love,
My Social Dog

My Social Dog is the first social network to connect local
dog owners in real-time. It links together neighbors, giving
them the ability to chat and set up playdates on the fly.

  MSG
end
