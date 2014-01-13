class AdminController < ApplicationController
  before_filter :require_user
  before_filter :admin_required
  before_filter :load_users, :only => [:change_username, :index]
  
  def index
    
  end
  
  def change_username
    @user = User.find(params[:id])
    @user.login = params[:login]
    @conflict = User.find_by_normalized_login(params[:login])
    if @user.login_changed? && (@conflict.nil? || @conflict.id == @user.id) && @user.save(false) # Do not validate
      flash[:notice] = 'Username changed.'
      redirect_to :action => :index
    else
      flash[:error] = 'Username invalid or already used (or maybe you didn\'t change it).' # ??
      render :action => :index
    end
  end
  
  def destroy
    return unless request.delete?
    @user = User.find(params[:id])
    Update.connection.execute("UPDATE updates SET deleted_at = NOW() WHERE user_id = #{@user.id.to_i}")
    @user.update_attribute(:deleted_at, Time.now)
    flash[:notice] = 'User removed'
    redirect_to :action => :index
  end
  
  def restore
    return unless request.post?
    @user = User.find(params[:id])
    Update.connection.execute("UPDATE updates SET deleted_at = NULL WHERE user_id = #{@user.id.to_i}")
    @user.update_attribute(:deleted_at, nil)
    flash[:notice] = 'User restored'
    redirect_to :action => :index
  end
  
  private
  
  def admin_required
    redirect_to '/' and return false unless current_user && current_user.admin?
  end
  
  def load_users
    conds = params[:q].blank? ? [] : ['login LIKE ? OR email LIKE ?', "%#{params[:q]}%", "%#{params[:q]}%"]
    @users = User.all(:conditions => conds).paginate(:page => params[:page], :per_page => 10)
  end
end
