class UsersController < ApplicationController
  
  before_action :signed_in_user,  only: [:index, :edit, :update, :destroy, :following, :followers, :slug]
  before_action :correct_user,    only: [:edit, :update]
  before_action :admin_user,      only: :destroy

  def index
    @users = User.paginate(page: params[:page])
  end

  def show
    @user = User.friendly.find(params[:id])
    if request.path != user_path(@user)
      redirect_to @user, status: :moved_permanently
    end
    @microposts = @user.microposts.paginate(page: params[:page])
  end

  def new
    if signed_in?
      redirect_to(root_path)
    else
      @user = User.new
    end
  end

  def create
    if signed_in?
      redirect_to(root_path)
    else
      @user = User.new(user_params)
      # puts "valid? = #{@user.valid?.inspect}"
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
  end

  def update
    if @user.update_attributes(user_params)
      flash[:success] = "Profile updated"
      sign_in @user
      redirect_to @user
    else
      render 'edit'
    end
  end


  def destroy
    @user = User.friendly.find(params[:id])
    if @user.admin?
      flash[:error] = "Invalid: Admin cannot delete itself!"
      redirect_to(root_path)
    else
      @user.destroy
      flash[:success] = "User destroyed."
      redirect_to users_url
    end
  end

  def following
      @title = "Following"
      @user = User.friendly.find(params[:id])
      @users = @user.followed_users.paginate(page: params[:page])
      render 'show_follow'
  end
  
  def followers
      @title = "Followers"
      @user = User.friendly.find(params[:id])
      @users = @user.followers.paginate(page: params[:page])
      render 'show_follow'
  end

  private

  def user_params
		params.require(:user).permit(:name, :email, :password, 
									               :password_confirmation, :slug)
	end

  # Before filters

  def correct_user
      @user = User.friendly.find(params[:id])
      redirect_to(root_url) unless current_user?(@user)
  end

  def admin_user
    redirect_to(root_url) unless (current_user && current_user.admin?)
  end

end

# 
