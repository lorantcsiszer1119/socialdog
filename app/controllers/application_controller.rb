# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include ExceptionNotifiable
  
  HTTP_AUTH_PAIRS = { 'k1ng' => 'k0g' }.freeze
  
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  helper_method :current_user_session, :current_user
  filter_parameter_logging :password, :password_confirmation
  
  before_filter :set_facebook_session
  
  before_filter :set_time_zone
  #before_filter :authenticate_with_http if RAILS_ENV == 'production'
  
  private
  
  def set_time_zone
    Time.zone = current_user.time_zone if current_user
  end
  
  def authenticate_with_http
    authenticate_or_request_with_http_basic('My Social Dog') do |username, password|
      HTTP_AUTH_PAIRS.has_key?(username) && HTTP_AUTH_PAIRS[username] == password
    end
  end
  
  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end
  
  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.record
  end
  
  def require_user
    unless current_user
      store_location
      flash[:notice] = "You must be logged in to access this page"
      redirect_to new_user_session_url
      return false
    end
  end

  def require_no_user
    if current_user
      store_location
      flash[:notice] = "You must be logged out to access this page"
      redirect_to account_url
      return false
    end
  end
  
  def store_location
    session[:return_to] = request.request_uri
  end
  
  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end
end
