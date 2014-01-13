# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_socialdog_session',
  :secret      => 'c76578ba01760d19d7ac197ee540e0d01e939b9dfe4dd92d52be7f3afb75f4e117c3b903fe4631002c8f8c8b87fc7aada2431ec94b7f9962afaa5d631533748f'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
