module TwitterAuth
  
  def self.config
    @config ||= YAML.load(File.open(RAILS_ROOT + '/config/twitter_auth.yml').read)[RAILS_ENV]
  end
  
end