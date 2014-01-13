ActionController::Routing::Routes.draw do |map|
  
  # Dogs
  map.resources   :dogs, :member => [:add_owner, :remove_owner]
  map.dog_profile ':login/dog/:name', :controller => 'dogs', :action => 'show',
                                      :requirements => {:login => /[a-zA-Z0-9]+/i,
                                                        :name  => /[a-zA-Z0-9]+/i}
  
  # Updates
  map.hashtag         'hashtags/:hashtag/:zipcode', :controller => 'updates', :action => 'hashtag', :requirements => {:zipcode => /\d{5}/}
  map.hashtag         'hashtags/:hashtag',          :controller => 'updates', :action => 'hashtag'
  map.create_update   'updates/create', :controller => 'updates', :action => 'create', :conditions => { :method => :post }
  
  map.home_stream     'home.:format',     :controller => 'updates', :action => 'render_stream'
  map.replies_stream  'replies.:format',  :controller => 'updates', :action => 'render_stream'
  map.everyone_stream 'everyone.:format', :controller => 'updates', :action => 'render_stream'
  
  map.resources :updates, :collection => [:render_stream, :create_from_sms, :create_sponsored, :ajax_users_in_zipcode]
  
  map.search 'search.:format', :controller => 'search'
  
  # PM
  map.connect 'messages/sent', :controller => 'private_messages', :direction => 'from'
  map.connect 'messages',      :controller => 'private_messages', :direction => 'to'
  map.resources :private_messages
  
  # Sessions
  map.resource :user_session
  map.login 'login', :controller => 'user_sessions', :action => 'new'
  map.resources :password_resets
  
  # Users
  map.resource  :account, :controller => 'users'
  map.settings  'settings', :controller => 'users', :action => 'edit'
  map.resources :users, :member => [:toggle_brand]
  map.signup    'signup', :controller => 'users', :action => 'new'
  map.friends   'friends', :controller => 'follows', :action => 'for_current_user'
  
  # Invites
  map.resources :invites
  map.route     'invite', :controller => 'invites', :action => 'index'
  
  # Follows
  map.friend_requests 'friend_requests', :controller => 'follows', :action => 'friend_requests'
  map.create_follow   'follows/create/:login',  :controller => 'follows', :action => 'create'
  map.destroy_follow  'follows/destroy/:login', :controller => 'follows', :action => 'destroy'
  map.connect 'follows/approve', :controller => 'follows', :action => 'approve'
  map.connect 'follows/deny',    :controller => 'follows', :action => 'deny'
  
  # Static pages
  map.connect 'pages/:slug', :controller => 'pages', :action => 'static_page'
  
  # Community (11211)
  map.community_stream ':zipcode.:format', :controller => 'updates', :action => 'render_stream',
                                           :requirements => {:zipcode => /\d{5}/}
  
  # Neighbors
  map.neighbors 'neighbors/:zipcode', :controller => 'users', :action => 'neighbors', :requirements => {:zipcode => /\d{5}/}
  map.neighbors 'neighbors', :controller => 'users', :action => 'neighbors'
  
  # Admin
  map.admin 'admin/:action/:id', :controller => 'admin'
  
  # Users + other routes tied to /username
  map.connect ':login/updates/:id', :controller => 'updates',
                                    :action => 'show', :requirements => {:login => /[a-zA-Z0-9]+/i, :id => /\d+/ }
  map.connect ':login/friends',     :controller => 'follows',
                                    :action => 'for_user', :requirements => {:login => /[a-zA-Z0-9]+/i}
  map.connect ':login.:format',     :controller => 'users',
                                    :action => 'show', :requirements => {:login => /[a-zA-Z0-9]+/i}
  
  
  
  map.root :controller => 'updates'

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
