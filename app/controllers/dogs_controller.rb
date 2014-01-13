class DogsController < ApplicationController
  before_filter :require_user
  
  def show
    @user = User.find_by_normalized_login(params[:login])
    @dog  = Dog.find_by_normalized_username(params[:name])
    
    # Other dogs in family
    @family_dogs    = []
    @family_dog_ids = []
    @dog.users.each do |u|
      u.dogs.each do |d|
        @family_dogs << d unless d.id == @dog.id
      end
    end
    @family_dogs.collect {|d| @family_dog_ids << d.id}
    
    # Other dogs I play with, which are all dogs of all followers of @user that aren't in @family_dogs
    @other_dogs   = []
    other_dog_ids = []
    @user.follows.each do |u|
      u.dogs.each do |d|
        @other_dogs << d unless (d.id == @dog.id) || @family_dog_ids.include?(d.id) || other_dog_ids.include?(d.id)
        other_dog_ids << d.id
      end
    end
    
    redirect_to "/#{@user.login}" and return unless @user.owner_of?(@dog)
    
    @page_title = "#{@dog.real_name}, #{@user.login}'s Social Dog"
    @cur_nav    = 'profile'
  end
  
  def add_owner
    return unless request.post?
    
    @dog = Dog.find(params[:id])
    if current_user.owner_of?(@dog)
      @new_owner = User.find_by_normalized_login(params[:username])
      @dog.users << @new_owner unless @new_owner.nil? || @new_owner.owner_of?(@dog)
      flash[:notice] = 'Owners updated.'
    end
    
    redirect_to edit_dog_path(@dog)
  end
  
  def remove_owner
    @dog = Dog.find(params[:id])
    if current_user.owner_of?(@dog)
      @dog.users.delete(User.find(params[:user_id]))
      flash[:notice] = 'Owners updated.'
    end
    
    redirect_to edit_dog_path(@dog)
  end
  
  def new
    @dog = current_user.dogs.new
    @page_title = 'Add a new dog'
    @cur_nav    = 'settings'
  end
  
  def create
    @dog = current_user.dogs.new(params[:dog])
    @page_title = 'Add a new dog'
    @cur_nav    = 'settings'
    @dog.first_user_id = current_user.id
    if @dog.save
      current_user.dogs << @dog
      flash[:notice] = "We've added #{@dog.real_name} to your profile!"
      redirect_to edit_account_path
    else
      render :action => :new
    end
  end
  
  def edit
    @dog = current_user.dogs.find(params[:id])
    @page_title = 'Edit Dog'
    @cur_nav    = 'settings'
  end
  
  def update
    @dog = Dog.find(params[:id])
    redirect_to edit_account_path unless current_user.owner_of?(@dog)
    @page_title = 'Edit Dog'
    @cur_nav    = 'settings'
    if @dog.update_attributes(params[:dog])
      flash[:notice] = "Your dog #{@dog.real_name} has been updated."
      redirect_to edit_account_path
    else
      render :action => :edit
    end
  end
  
  def destroy
    return unless request.post?
    @dog = Dog.find(params[:id])
    if current_user.owner_of?(@dog)
      @dog.destroy
      flash[:notice] = "Your dog #{@dog.real_name} has been removed."
    end
    redirect_to edit_account_path
  end
end
