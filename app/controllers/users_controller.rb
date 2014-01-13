class UsersController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:edit, :update, :toggle_brand, :neighbors]
  
  def neighbors
    # Miles and distance results
    @zoom_miles = params[:miles].to_i if params[:miles]
    
    # Get zipcode
    @zipcode = params[:zipcode] || current_user.zipcode
    zip = Zipcode.find_by_strict_type_cast(@zipcode)
    if zip == nil
      # Need to create & geocode zipcode
      zip = Zipcode.create(:zipcode => @zipcode.to_s)
    end
    
    @page_title = "Your Neighbors in #{@zipcode}"
    @cur_nav    = 'neighbors'
    
    unless @zoom_miles
      conds = ['users.id <> ? AND users.zipcode = ?', current_user.id, @zipcode]
    else
      # Need to show all users within N miles
      conds = ['users.id <> ?', current_user.id]
    end
    
    # TODO figure out how to paginate this later...
    @users = User.find(:all,
                       :conditions => conds,
                       :include    => [:updates],
                       :order      => 'users.is_brand DESC, users.bio ASC')
                       
    @keep_zipcodes = []
    @keep_users    = []
                      
    # Pop users who are not within N miles if we're zooming
    if @zoom_miles && @zoom_miles.to_i > 0
      @users.each_with_index do |user,idx|
        
        # Memoize zipcodes to include to avoid costly calls to haversine_distance()
        # TODO also apply to community zoom (and hashtag pages)
        if @keep_zipcodes.include?(user.zipcode.to_s)
          logger.info "neighbors() keeping #{user.id} -> memoized #{user.zipcode}"
          @keep_users << user
        else
          md = user.zipcode_metadata
          if md.nil?
            logger.info "neighbors() no zipcode metadata for #{user.id}"
          else
        
            hd = md.haversine_distance(zip.lat.to_f, zip.lon.to_f, md.lat.to_f, md.lon.to_f)
            logger.info "neighbors() hd -> #{hd.inspect}"
            logger.info "neighbors() miles -> #{@zoom_miles}"
            if hd && (hd['mi'] > @zoom_miles.to_f || (hd['mi'].to_i == 0 && md.zipcode != zip.zipcode))
              logger.info "neighbors() popped #{user.id} - #{hd['m']}"
            else
              logger.info "neighbors() adding #{user.zipcode} to keeps"
              @keep_zipcodes << user.zipcode
              @keep_users << user
            end
        
          end
        end
        
      end
      
      @users = @keep_users.paginate(:page => params[:page], :per_page => 10)
    
    else  
      @users = @users.paginate(:page => params[:page], :per_page => 10)
    end
  end
  
  def new
    @is_ajax = true if params[:ajax].to_i == 1
    @page_title = 'Sign Up'
    
    @user = User.new
    
    render 'new', :layout => false if @is_ajax
  end
  
  def create
    @is_ajax = false
    @page_title = 'Sign Up'
    
    @user = User.new(params[:user])
    if @user.save
      Delayed::Job.enqueue EmailJob.new(:welcome, {:user_id => @user.id})
      
      # Make them follow mysocialdog
      if RAILS_ENV == 'production'
        msd = User.find_by_login('mysocialdog')
        @user.follow!(msd)
        msd.follow!(@user)
      end
      
      if params[:follow]
        # Follow (from invite)
        fu = User.find_by_normalized_login(params[:follow])
        if fu
          @user.follow!(fu)
          fu.follow!(@user)
        end
      end
      
      # Points
      @user.point_awards.create(:context => 'signup_bonus', :value => 5)
      
      flash[:notice] = "Welcome to My Social Dog!"
      redirect_back_or_default home_stream_path
    else
      render :action => :new
    end
  end
  
  def show
    redirect_to home_stream_path and return unless params[:login]
    @user = User.find_by_normalized_login(params[:login])
    redirect_to home_stream_path and return if @user.nil? || @user.deleted_at
    
    @updates = @user.updates.find(:all,
                                  :order => 'created_at DESC',
                                  :limit => Update::PER_PAGE)
    
    @page_title   = "#{@user.login} - #{@user.real_name}"
    @page_title << " - #{@user.zipcode}" unless @user.is_brand?
    @cur_nav      = 'profile'
    @view_segment = 'user'
    
    respond_to do |format|
      format.html
      format.rss  { render 'shared/feed', :layout => false }
    end
  end
 
  def edit
    @page_title = 'Account Settings'
    @cur_nav    = 'settings'
    @user       = @current_user
  end
  
  def update
    @page_title = 'Account Settings'
    @cur_nav    = 'settings'
    @user       = @current_user # makes our views "cleaner" and more consistent
    if @user.update_attributes(params[:user])
      if params[:remove_photo].to_i == 1
        @user.avatar.destroy
        @user.avatar = nil 
        @user.save
      end
      flash[:notice] = "Settings saved!"
      redirect_to home_stream_path
    else
      render :action => :edit
    end
  end
  
  def toggle_brand
    return unless current_user && current_user.admin?
    
    u = User.find(params[:id])
    u.toggle!(:is_brand)
    
    flash[:notice] = 'User brand status updated'
    redirect_to "/#{u.login}"
  end
  
  def destroy
    return unless request.delete?
    @user = @current_user
    # FIXME Make this better?
    Update.connection.execute("UPDATE updates SET deleted_at = NOW() WHERE user_id = #{@user.id.to_i}")
    @user.update_attribute(:deleted_at, Time.now)
    current_user_session.destroy
    flash[:notice] = 'Your account has been removed.'
    redirect_to '/'
  end
end
