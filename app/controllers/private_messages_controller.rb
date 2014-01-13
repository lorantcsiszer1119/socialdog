class PrivateMessagesController < ApplicationController
  before_filter :require_user
  
  def index
    @which = params[:direction] || 'to'
    @extra_header    = "Private messages #{@which == 'to' ? 'sent to you' : 'you\'ve sent'}"
    @page_title      = @extra_header
    @cur_nav         = 'messages'
    @private_message = PrivateMessage.new({
      :user_id      => current_user.id,
      :from_user_id => current_user.id
    })
    
    if @which == 'to'
      @private_messages = PrivateMessage.paginate_all_by_to_user_id(current_user.id,
                                                                :order => 'created_at DESC',
                                                                :per_page => 5,
                                                                :page => params[:page])
    else
      @private_messages = PrivateMessage.paginate_all_by_from_user_id(current_user.id,
                                                                  :order => 'created_at DESC',
                                                                  :per_page => 5,
                                                                  :page => params[:page])
    end
  end
  
  def create
    @private_message              = PrivateMessage.new(params[:private_message])
    @private_message.user_id      = current_user.id
    @private_message.from_user_id = current_user.id
    
    # Look up the receiving user
    @to_user = User.find_by_normalized_login(params[:to_user])
    if !@to_user
      flash[:error] = 'There was a problem sending your private message'
      redirect_to :action => :index and return
    end
    
    @private_message.to_user_id = @to_user.id
    
    if @private_message.save
      flash[:notice] = "Your private message has been sent to #{@to_user.login}."
      redirect_to :action => :index and return
    else
      flash[:error] = 'There was a problem sending your private message'
      redirect_to :action => :index and return
    end
  end
end
