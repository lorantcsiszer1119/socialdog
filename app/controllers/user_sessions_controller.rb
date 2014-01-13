class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy
  
  def new
    @user_session = UserSession.new
    @page_title = 'Log In'
  end
  
  def create
    @user_session = UserSession.new(params[:user_session])
    @page_title = 'Log In'
    if @user_session.save
      # Check for deleted account
      if @user_session.record.deleted_at
        @user_session.destroy
        flash[:error] = 'That account has been deleted.'
        redirect_to '/' and return
      end
      flash[:notice] = "Welcome back friend!"
      redirect_back_or_default '/home'
    else
      render :action => :new
    end
  end
  
  def destroy
    current_user_session.destroy
    flash[:notice] = "See you later!"
    redirect_back_or_default '/'
  end
end
