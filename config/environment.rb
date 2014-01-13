# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.4' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# GMaps keys
GOOGLE_MAPS_KEYS = {
  :development => 'ABQIAAAA1aJ05cLvoEYpWsLBdPzeXhQD3HXPGV_kowejAys29DMOPOckJBS4Z4lM3D6p-O4vUVFJaBEnxSuvAQ',
  :production  => 'ABQIAAAA1aJ05cLvoEYpWsLBdPzeXhTSXr_UuYLJm-GGBTQa16hfyYrzHxQuqWVAyhAM4PKHcrqlnbO_7_A_fg'
}

# S3 Buckets
S3_BUCKETS = { 'development' => 'msddev', 'production' => 'mysocialdogavatars' }.freeze

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Specify gems that this application depends on and have them installed with rake gems:install
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "sqlite3-ruby", :lib => "sqlite3"
  # config.gem "aws-s3", :lib => "aws/s3"
  
  config.gem 'authlogic'
  config.gem 'redgreen'
  config.gem 'mislav-will_paginate', :version => '>= 2.3.6', :lib => 'will_paginate', :source => 'http://gems.github.com'
  config.gem 'oauth'
  config.gem 'json'
  config.gem 'facebooker'

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
  
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings   = {
    :address         => "smtp.gmail.com",
    :port            => 587, 
    :domain          => "mysocialdog.com",
    :user_name       => "no-reply@mysocialdog.com",
    :password        => "n0reply321",
    :authentication  => :plain,
    :tls             => true
  }
end

# Change divs to spans for .field_with_errors
ActionView::Base.field_error_proc = Proc.new {|html_tag, instance|  %(<span class="field_with_errors">#{html_tag}</span>)}

# Delayed jobs
require 'lib/jobs/email.rb'

# EN
ExceptionNotifier.exception_recipients = %w{kyle@mysocialdog.com}
ExceptionNotifier.sender_address = %("Application Error" <no-reply@mysocialdog.com>)
ExceptionNotifier.email_prefix = '[APP ERROR] '

# OAuth
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE