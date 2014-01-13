require 'open-uri'

class UpdatesController < ApplicationController
  # TODO render_stream requires auth, but this breaks logged-out user profiles...
  before_filter :require_user, :only => [:render_stream, :create, :destroy, :show, :create_sponsored, :hashtag]
  before_filter :preset_view_vars
  
  protect_from_forgery :except => :create_from_sms
  
  TM_PRIVATE_TOKEN = 'hz8D6IfHyvY3xGkb4Cnb3JAA'
  
  def index
    if current_user
      redirect_to home_stream_path
    else
      @is_homepage = @no_landscape = true
      @page_title = 'Helping Local Dog Owners Connect in Real-Time'
      render 'pages/homepage'
    end
  end
  
  def show
    @user   = User.find_by_normalized_login(params[:login])
    raise ActiveRecord::RecordNotFound if @user && @user.deleted_at
    @update = @user.updates.find(params[:id])
    
    @single = @last = true
    
    @cur_nav    = 'profile'
    @page_title = "#{@user.login}: #{@update.body}"
  end
  
  def render_stream
    @zoom_miles = params[:miles].to_i if params[:miles] # For community stream
    
    @rss_in_head = true
    
    if params[:ajax].nil?
      segment     = request.path.gsub(/^\//, '').gsub(/\.rss$/, '')
      ajax        = false
      last_id_sql = ''
      
      @rss_in_head_segment = "#{segment}.rss"
      
      # Community?
      if segment =~ /\d{5}/ && params[:zipcode]
        segment  = 'community'
        @zipcode = params[:zipcode]
      end
    else
      segment     = params[:view]
      ajax        = true
      last_id_sql = " AND updates.id < #{params[:last_id].to_i}" # FIXME make this a bind var
      @zipcode    = params[:zipcode] if params[:zipcode]
    end
    
    # Push sponsored messages
    # TODO:
    # - only find updates that are newer than the oldest update in @updates
    # - expand to include targeting demographics, etc.
    # - only for home, everyone, community?
    if !segment.blank? && [:home, :community, :everyone].include?(segment.to_sym)
      is_spons = 'false or is_sponsored = true'
      #smsg = Update.find_all_by_is_sponsored(true)
      #unless smsg.empty?
      #  @updates << smsg
      #  @updates = @updates.flatten.sort{|a,b| b.updated_at <=> a.updated_at}
      #  
      #  # Pop anything > PER_PAGE
      #  if @updates.size > Update::PER_PAGE
      #    @updates.pop while @updates.size > Update::PER_PAGE
      #  end
      #end
    else
      is_spons = 'false'
    end
    
    # Stream content
    case segment.to_sym
    when :home
      user_ids    = [current_user.id].push(current_user.follows.collect(&:id)).flatten
      @page_title = 'Home'
      @cur_nav    = 'home'
      @updates    = Update.find(:all,
                                :conditions => ["deleted_at IS NULL AND (is_sponsored = true OR ((is_sponsored = #{is_spons}) AND user_id IN (?) #{last_id_sql}))", user_ids],
                                :order      => 'created_at DESC',
                                :limit      => Update::PER_PAGE)
      
    # FIXME This will most certainly not scale when 100s or 1000s+ updates exist
    when :community
      @extra_header = (current_user.zipcode == @zipcode) ? "Your Community" : "Everyone in #{@zipcode}"
      @page_title = @extra_header
      @cur_nav    = 'community'
      if @zoom_miles && @zoom_miles > 0
        @updates = Update.find(:all,
                               :joins => 'LEFT JOIN users ON users.id = updates.user_id',
                               :conditions => ["updates.deleted_at IS NULL AND (is_sponsored = #{is_spons}) AND (users.zipcode = ? OR 1=1) #{last_id_sql}", "#{@zipcode}"],
                               :order => 'created_at DESC')
        # Pop any updates that aren't within N miles
        zip = Zipcode.find_by_strict_type_cast(@zipcode)
        if zip == nil
          # Need to create & geocode zipcode
          zip = Zipcode.create(:zipcode => @zipcode.to_s)
        end
        @updates.delete_if { |up|
          md = up.user.zipcode_metadata
          if md.nil?
            logger.info "no zipcode metadata for #{up.id}"
            true
          else
          
            hd = md.haversine_distance(zip.lat.to_f, zip.lon.to_f, md.lat.to_f, md.lon.to_f)
            logger.info hd.inspect
            logger.info @zoom_miles
            if hd && (hd['mi'] > @zoom_miles.to_f || (hd['mi'].to_i == 0 && md.zipcode != zip.zipcode))
              logger.info "popped #{up.id} - #{hd['m']}"
              true
            end
            
          end
        }
        
        # Reduce the set to PER_PAGE, in reverse order
        while @updates.size > Update::PER_PAGE
          @updates.pop
        end
      else
        @updates = Update.find(:all,
                               :joins => 'LEFT JOIN users ON users.id = updates.user_id',
                               :conditions => ["updates.deleted_at IS NULL AND (is_sponsored = #{is_spons}) AND users.zipcode = ? #{last_id_sql}", "#{@zipcode}"],
                               :order => 'created_at DESC',
                               :limit => Update::PER_PAGE)
      end
    
    when :everyone
      @extra_header = 'Everyone on My Social Dog'
      @page_title = 'Everyone'
      @cur_nav    = 'everyone'
      @updates    = Update.find(:all,
                                :conditions => ["deleted_at IS NULL AND (is_sponsored = #{is_spons}) #{last_id_sql}"],
                                :order => 'created_at DESC',
                                :limit => Update::PER_PAGE)
      
    when :user
      # Ajax only
      segment  = 'user'
      @user    = User.find(params[:user_id])
      @updates = @user.updates.find(:all,
                                    :conditions => ["deleted_at IS NULL AND (is_sponsored = #{is_spons}) AND id < ?", params[:last_id].to_i],
                                    :order      => 'created_at DESC',
                                    :limit      => Update::PER_PAGE)
      @single_user = true
    
    when :replies
      @extra_header = 'Replies'
      @page_title   = 'Replies'
      @cur_nav      = 'replies'
      @no_post_form = true
      
      @updates = Update.find_by_sql(["SELECT updates.* FROM updates
                                      WHERE deleted_at IS NULL AND (reply_to_username = ? OR
                                      ((body LIKE ?
                                        OR body LIKE ?
                                        OR body LIKE ?)
                                      AND user_id <> ?)) #{last_id_sql}
                                      AND (is_sponsored = #{is_spons})
                                      ORDER BY created_at DESC
                                      LIMIT #{Update::PER_PAGE}",
                                      current_user.login,           # match on reply_to_username
                                      "@#{current_user.login} %",   # First
                                      "% @#{current_user.login} %", # Middle
                                      "% @#{current_user.login}",   # Last
                                      current_user.id])
      
      
    end
    
    # For new update form & update JS
    @update       = current_user.updates.new
    @view_segment = segment
    
    if ajax
      render 'ajax_next_batch', :layout => false
    else
      respond_to do |format|
        format.html { render 'stream' }
        format.rss  { render 'shared/feed', :layout => false }
      end
    end
  end
  
  def create
    redirect_to home_stream_path and return unless request.post?
    
    @update = current_user.updates.new(params[:update])
    ret     = @update.pre_process!(current_user)
    
    # Force this update to be in reply to a specific update
    begin
      if params[:force_reply_to_user] && params[:force_last_update_id]
        reply_user = User.find_by_normalized_login(params[:force_reply_to_user])
        reply_up   = reply_user.updates.find(params[:force_last_update_id].to_i) if reply_user
        reply_up   = Update.find(params[:force_last_update_id].to_i) unless reply_user
        reply_user = reply_up.user unless reply_user
        if reply_user && reply_up
          @update.reply_to_username = reply_user.login
          @update.reply_to_user_id  = reply_user.id
          @update.reply_to_id       = reply_up.id
        end
      end
    rescue => e
      #raise e if Rails.env.development?
    end
    
    if ret == false && @update.save
      
      # Create a bit.ly link if posting to twitter and/or fb
      if current_user.twitter_linked? || current_user.facebook_connect_user?
        bitly_key = 'R_ddb794f4e102a70e5450f0ee60e72588'
        endpoint = "http://api.bit.ly/shorten?version=2.0.1&longUrl=http://www.mysocialdog.com/#{current_user.login}/updates/#{@update.id}&login=kyle&apiKey=#{bitly_key}"
        begin
          bitly_link = JSON.parse(open(endpoint).read)
          bitly_link = bitly_link['results'][bitly_link['results'].keys.first]['shortUrl']
        rescue => e
          bitly_link = false
        end
      end
      
      upbod = @update.body
      if bitly_link
        bl    = " (#{bitly_link} @mysocialdog)" # bit.ly link and @mysocialdog
        tlen  = bl.length # Length of link + @mysocialdog
        subt  = 140 - tlen - 5 # Chars remaining after link/@msd inserted
        truncbod = @update.body[0, subt] # Truncated body
        truncbod << '...' if truncbod.length != @update.body.length # Add ellipsis if body was actually truncated
        upbod = truncbod << ' ' << bl # Put it all together
      end
      
      # Twitter?
      if params[:send_twitter] && current_user.twitter_linked?
        current_user.twitter_user.post_update(upbod)
      end
      # FB?
      if params[:send_facebook] && current_user.facebook_connect_user? && facebook_session
        facebook_session.user.set_status(upbod)
      end
      
      # First?
      if current_user.updates.size == 1
        current_user.point_awards.create(:context => 'first_update', :value => 5)
      end
      
      flash[:notice] = 'Update posted!'
    else
      flash[ret[:flash_type]] = ret[:flash] if ret.is_a?(Hash)
    end
    
    redirect_to params[:from]
  end
  
  def create_from_sms
    return unless request.post?
    begin
      u    = params[:sender] # Phone #
      m    = params[:message] # Text
      key  = '' #params[:key]
      auth = '' #params[:auth]
      
      # Sanitize params
      u = u.gsub(/[^\d]/, '')[1, 10]
      m = m.strip
      
      # Find user by mobile
      @user   = User.find(:first, :conditions => ['mobile_number = ?', u])
      @update = @user.updates.new({
        :posted_via => 'mobile',
        :body       => m
      })
      ret = @update.pre_process!(@user)
      @update.save if ret == false
    rescue => e
      raise e
    ensure
      render :nothing => true, :status => 200
    end
  end
  
  def create_sponsored
    return unless current_user.admin?
    
    @update = Update.new
    
    if request.post?
      @update = Update.new(params[:update])
      @update.is_sponsored = true
      
      if !params[:user_ids] || (params[:user_ids] && params[:user_ids].empty?)
        flash[:error] = 'Please choose a brand, users to target, and enter a message'
      else
      
        unless @update.user_id.nil? || @update.body.blank?
          @update.save
          flash[:notice] = 'Sponsored message created'
          redirect_to home_stream_path
        else
          flash[:error] = 'Please choose a brand, users to target, and enter a message'
        end
        
      end
    end
  end
  
  def ajax_users_in_zipcode
    return unless current_user.admin?
    @users = User.find_all_by_zipcode(params[:zipcode])
    render :partial => 'ajax_users_in_zipcode'
  end
  
  def destroy
    u = current_user.updates.find(params[:id])
    u.destroy
    flash[:notice] = 'Update destroyed.'
    redirect_to home_stream_path
  end
  
  # Hashtag page
  def hashtag
    @hashtag = params[:hashtag]
    
    # Miles and distance results
    @zoom_miles = params[:miles].to_i if params[:miles]
    
    # Get zipcode
    @zipcode = params[:zipcode] || current_user.zipcode
    zip = Zipcode.find_by_strict_type_cast(@zipcode)
    if zip == nil
      # Need to create & geocode zipcode
      zip = Zipcode.create(:zipcode => @zipcode.to_s)
    end
    
    @page_title = "#{@hashtag} in #{@zipcode}"
    @cur_nav    = 'search'
    
    @view_segment = 'everyone'
    
    if @zoom_miles
      @updates = Update.find_by_sql(['SELECT * FROM updates
                                    WHERE deleted_at IS NULL AND
                                      body LIKE ? OR body LIKE ? OR body LIKE ?
                                      ORDER BY created_at DESC',
                                      "##{@hashtag} %", "% ##{@hashtag}", "% ##{@hashtag} %"])
    else
      @updates = Update.find_by_sql(['SELECT updates.* FROM updates
                                    INNER JOIN users ON updates.user_id = users.id
                                    WHERE updates.deleted_at IS NULL AND
                                      users.zipcode = ? AND
                                      (updates.body LIKE ? OR updates.body LIKE ? OR updates.body LIKE ?)
                                      ORDER BY updates.created_at DESC',
                                      @zipcode, "##{@hashtag} %", "% ##{@hashtag}", "% ##{@hashtag} %"])
    end
    
    if @zoom_miles && @zoom_miles.to_i > 0
      @updates.delete_if { |up|
        md = up.user.zipcode_metadata
        if md.nil?
          logger.info "no zipcode metadata for #{up.id}"
          true
        else
        
          hd = md.haversine_distance(zip.lat.to_f, zip.lon.to_f, md.lat.to_f, md.lon.to_f)
          logger.info hd.inspect
          logger.info @zoom_miles
          if hd && (hd['mi'] > @zoom_miles.to_f || (hd['mi'].to_i == 0 && md.zipcode != zip.zipcode))
            logger.info "popped #{up.id} - #{hd['m']}"
            true
          end
          
        end
      }
    end
  end
  
  private
  
  def preset_view_vars
    @no_delete      = false # Only for search
    @single_user    = false
    @single         = false
    @last           = false
    @no_post_form   = false # Hide new update box?
  end
end
