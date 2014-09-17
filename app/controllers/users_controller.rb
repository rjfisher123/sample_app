class UsersController < ApplicationController
  
  before_action :signed_in_user,  only: [:index, :edit, :update, :destroy, :following, :followers, :slug]
  before_action :correct_user,    only: [:edit, :update]
  before_action :admin_user,      only: :destroy

  def index
    # Chapter 9.33 Using the will_paginate gem.
    # Note params[:page] is generated automatically by will_paginate.
    # Default chunk size is 30 items.
    # @users = User.paginate(page: params[:page])

    # Using pg_search for full text search and kaminari gem to paginate
    @users = User.search(params[:query]).page params[:page]
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
      respond_to do |format|
        if @user.save
          sign_in @user
          flash[:success] = "Welcome to the Sample App!"
          UserMailer.registration_confirmation(@user).deliver
          format.html { redirect_to @user }
          format.xml  { render :xml => @user, :status => :created, :location => @user }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
        end
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
									               :password_confirmation, :slug, :notifications)
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
