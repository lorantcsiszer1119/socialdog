class InvitesController < ApplicationController
  before_filter :require_user
  
  def index
    @cur_nav    = 'invite'
    @page_title = 'Invite Friends'
    @invites    = current_user.invites
    @invite     = Invite.new
  end
  
  def create
    # Ideal Flow:
    #
    # Try to find user by email (or maybe they can enter multiple emails, one per line)
    # if user found:
    # - if already a user, make current_user follow that user
    # - if not a user, see if invite exists already
    # -- if no invite exists yet, create and send
    #
    # Redeeming invite:
    # - By guid - when invited user finishes signup, they auto-follow and vice-versa the inviting user;
    # - invitation is marked used
    #
    # For now, just send emails to each email address that isn't already a user (if they are, do the auto-follow thing)
    # The email links to a special signup url with a follow=username pair
    
    emails = []
    
    @cur_nav    = 'invite'
    @page_title = 'Invite Friends'
    @invites    = current_user.invites
    @invite     = Invite.new
    
    params[:emails].split("\n").each do |email|
      emails << email.strip unless email.strip.blank?
    end
    emails.delete(current_user.email) # Just in case
    
    if emails.empty?
      flash.now[:error] = 'Please enter at least one email address.'
      render :action => :index and return
    end
    
    emails.each do |email|
      email = email.downcase
      u     = User.find_by_email(email)
      inv   = Invite.find_by_user_id_and_email(current_user.id, email)
      unless inv # Don't send multiple invites for the same user/email pair
        if u
          # Follow this user
          current_user.follow!(u)
        else
          # Send invite email
          Invite.create({
            :user_id => current_user.id,
            :message => params[:invite][:message],
            :email   => email
          })
          Delayed::Job.enqueue EmailJob.new(:invite,
                                           {:from => current_user.id, :to => email, :msg => params[:invite][:message]})
        end
      end
    end
    flash[:notice] = 'Invites sent!' unless emails.empty?
    redirect_to invites_path
  end
end
