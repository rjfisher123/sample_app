class UsersController < ApplicationController
  
  before_action :signed_in_user,  only: [:index, :edit, :update, :destroy]
  before_action :correct_user,    only: [:edit, :update]
  before_action :admin_user,      only: :destroy

  def index
    @users = User.paginate(page: params[:page])
  end

  def show
  	@user = User.find(params[:id])
  end

  def new
  	if signed_in?
      redirect_to root_url
      flash[:notify] = '!Please log-out before Singing-up'
    else
      @user = User.new
    end
  end

  def create
    if signed_in?
      redirect_to root_path
      flash[:notify] = '!Please log-out before Singing-up'
    else
      @user = User.new(user_params)
      if @user.save
        sign_in @user
        flash[:success] = "Welcome to the Sample App!"
        redirect_to @user
      else
        render 'new'
      end
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update_attributes(user_params)
      flash[:success] = "Profile updated"
      redirect_to @user
    else
      render 'edit'
    end
  end

  def destroy
    @user = User.find(params[:id])
    if @user.admin?
      puts "The current user is:"+current_user.name
      puts "Is user admin?:"+current_user.admin.to_s
      flash[:error] = "Invalid: Admin cannot delete itself!"
      redirect_to(root_path)
    else
      @user.destroy
      flash[:success] = "User destroyed."
      redirect_to users_url
    end
  end

  def admin_user
    redirect_to(root_url) unless (current_user && current_user.admin?)
  end

  private

  def is_signed_in
    redirect_to(root_url) if signed_in?
    puts "signed in: #{is_signed_in}"
  end

	def user_params
		params.require(:user).permit(:name, :email, :password, 
									               :password_confirmation)
	end

  # Before filters

  def signed_in_user
    # debugger
    unless signed_in?
      store_location
      redirect_to signin_url, notice: "Please sign in."
    end
  end

  def correct_user
      @user = User.find(params[:id])
      redirect_to(root_url) unless current_user?(@user)
  end
end
