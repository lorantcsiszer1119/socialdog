class FollowsController < ApplicationController
  before_filter :require_user
  
  def for_current_user
    @user = @current_user
    render_follows
  end
  
  def approve
    @follow = Follow.find_by_id_and_follow_id(params[:id], current_user.id)
    @follow.update_attribute(:approved, true)
    flash[:notice] = 'Friend request approved.'
    # TODO send email?
    redirect_to '/friend_requests'
  end
  
  def deny
    @follow = Follow.find_by_id_and_follow_id(params[:id], current_user.id)
    @follow.destroy
    flash[:notice] = 'Friend request denied.'
    # TODO send email?
    redirect_to '/friend_requests'
  end
  
  def friend_requests
    @requests = current_user.follow_requests
  end
  
  def for_user
    @user = User.find_by_normalized_login(params[:login])
    render_follows
  end
  
  def create
    followed_user = User.find_by_normalized_login(params[:login])
    redirect_to '/' if followed_user.deleted_at
    current_user.follow!(followed_user)
    
    # Points
    if current_user.follows.size == 1
      # f1rst
      current_user.point_awards.create(:context => 'first_follow', :value => 1)
    end
    if followed_user.followers.size == 1
      # f1rst
      followed_user.point_awards.create(:context => 'first_follower', :value => 1)
    end
    
    unless current_user.follow_pending?(followed_user)
      Delayed::Job.enqueue EmailJob.new(:follow, {:from_user => current_user.id, :to_user => followed_user.id})
    else
      Delayed::Job.enqueue EmailJob.new(:friend_request, {:from_user => current_user.id, :to_user => followed_user.id})
    end
    flash[:notice] = current_user.follow_pending?(followed_user) ? "Your follow request has been sent." : "You are now following #{params[:login]}!"
    redirect_to "/#{params[:login]}"
  end
  
  def destroy
    current_user.unfollow!(User.find_by_normalized_login(params[:login]))
    flash[:notice] = "You have stopped following #{params[:login]}."
    redirect_to "/#{params[:login]}"
  end
  
  def toggle_follow_by
    return unless %{email sms}.include?(params[:by].downcase)
    
    follow_user = User.find(params[:user_id])
    return if follow_user.deleted_at
    by          = "by_#{params[:by]}"
    enabled     = params[:enable].to_i
    fo          = current_user.find_follow_object_for(follow_user)
    
    fo.update_attribute(by.to_sym, enabled)
    
    render :nothing => true, :status => 200
  end
  
  protected
  
  def render_follows
    @page_title = "Friends of #{@user.login}"
    @cur_nav    = 'friends'
    @no_rss     = true
    render 'friends'
  end
end
