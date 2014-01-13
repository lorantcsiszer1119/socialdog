class FacebookUsersController < ApplicationController
  before_filter :require_user
  
  def connect_callback
    if facebook_session
      # connect accounts
      current_user.link_fb_connect(facebook_session.user.id) unless current_user.fb_user_id == facebook_session.user.id
      @fbuser = current_user
      
      flash[:notice] = 'You have successfully linked your Facebook account.'
      redirect_to '/' and return
    else
      flash[:error] = 'Something went wrong with Facebook Connect. Please try again later.'
      redirect_to '/' and return
    end
  end
end
