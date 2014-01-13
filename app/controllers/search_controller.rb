class SearchController < ApplicationController
  # TODO probably need to paginate this...
  def index
    @page_title  = 'Search'
    @rss_in_head = true
    @terms = params[:q] ? params[:q] : ''
    @rss_in_head_segment = "search.rss?q={CGI.escape(@terms)}"
    unless @terms.blank?
      @page_title << " Results for \"#{@terms}\""
      @updates = Update.find(:all,
                             :conditions => ['LOWER(body) LIKE ?', "%#{@terms.downcase}%"],
                             :order => 'created_at DESC',
                             :limit => 50)
      @users = User.find(:all,
                         :conditions => ['LOWER(login) LIKE ? OR LOWER(real_name) LIKE ? OR zipcode = ?',
                                            "%#{@terms.downcase}%", "%#{@terms.downcase}%", "%#{@terms}%"],
                         :order => 'updated_at DESC',
                         :limit => 25)
    else
      @updates = []
      @users   = []
    end
    
    respond_to do |format|
      format.html
      format.rss  { render 'shared/feed', :layout => false }
    end
  end
end
