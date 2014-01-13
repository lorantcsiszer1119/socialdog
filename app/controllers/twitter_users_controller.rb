class TwitterUsersController < ApplicationController
  
  include TwitterAuth

  before_filter :require_user, :except => [:callback]

  # Pulled from http://apiwiki.twitter.com/OAuth+Example+-+Ruby, with a little twitter-oauth mixed in

  def self.consumer
    # The readkey and readsecret below are the values you get during registration
    options = {
      :site           => TwitterAuth.config['base_url'],
      :authorize_path => TwitterAuth.config['authorize_path']
    }
    OAuth::Consumer.new(TwitterAuth.config['oauth_consumer_key'], TwitterAuth.config['oauth_consumer_secret'], options)
  end

  def create
    redirect_to '/' and return if current_user.twitter_linked?

    @request_token = TwitterUsersController.consumer.get_request_token({:oauth_callback => TwitterAuth.config['oauth_callback']})

    session[:request_token]        = @request_token.token
    session[:request_token_secret] = @request_token.secret

    # Send to twitter.com to authorize
    url = @request_token.authorize_url
    url << "&oauth_callback=#{CGI.escape(TwitterAuth.config['oauth_callback'])}" if TwitterAuth.config['oauth_callback']
    redirect_to url and return
  end

  def destroy
    return unless request.post?
    return unless current_user.twitter_linked?
    @twitter_user = current_user.twitter_user
    @twitter_user.destroy
    flash[:notice] = 'Your Twitter account has been unlinked.'
    redirect_to '/'
  end

  def callback
    @request_token = OAuth::RequestToken.new(TwitterUsersController.consumer, session[:request_token], session[:request_token_secret])

    # Exchange the request token for an access token.
    oauth_verifier = params[:oauth_verifier]
    @access_token  = @request_token.get_access_token(:oauth_verifier => oauth_verifier)
    @response      = TwitterUsersController.consumer.request(:get, '/account/verify_credentials.json', @access_token, { :scheme => :query_string })

    # The request token has been invalidated
    # so we nullify it in the session.
    session[:request_token]        = nil
    session[:request_token_secret] = nil

    case @response
    when Net::HTTPSuccess

      user_info = JSON.parse(@response.body)
      unless user_info['screen_name']
        flash[:notice] = "We were unable to link your Twitter account. Please try again."
        redirect_to '/settings' and return
      end

      # Think about:
      # If we have an authorized user, save the information to the database.
      # If we have current_user, assume the user is linking their account (but don't link twice)
      # If not, assume the user is *creating* a new cork'd account using twitter...

      @twitter_user = TwitterUser.identify_or_create_by_access_token(current_user, @access_token)
      if @twitter_user

        # Success
        flash[:notice] = "Your Twitter account has been successfully linked!"
        redirect_to '/' and return

      else

        # Some error occurred...
        flash[:error] = "We were unable to link your Twitter account. Please try again."
        redirect_to '/settings' and return

      end

    end

    # If we get here, probably a 403 due to too many requests
    flash[:error] = "We were unable to link your Twitter account, probably due to API rate-limiting. Please try again later."
    redirect_to redirect_to '/settings' and return
  end

end
