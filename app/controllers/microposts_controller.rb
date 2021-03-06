class MicropostsController < ApplicationController
	
	include ReplyParser
	include MessageHandler

	before_action :signed_in_user#, only: [:create, :destroy]
	before_action :correct_user, only: :destroy
	before_action :check_if_message, only: :create
	

	def create
		@micropost = current_user.microposts.build(micropost_params)

		parse_recipient!(@micropost)

		if @micropost.save
		  redirect_to root_url, flash: { success: 'Micropost created' }
		else
		  @feed_items = []
		  render 'static_pages/home'
		end
	end

	def destroy
		@micropost.destroy
		redirect_to root_url, flash: { success: 'Micropost deleted' }
	end

	def show
		# @micropost = current_user.id.micropost_params(:id)
	    @micropost = Micropost.find(params[:id])
	    # if request.path != user_path(@user)
	    #   redirect_to @user, status: :moved_permanently
	    # end
	end
	
	private
		def micropost_params
			params.require(:micropost).permit(:content)
		end

		def correct_user
			@micropost = current_user.microposts.find_by(id: params[:id])
			redirect_to root_url if @micropost.nil?
		end
end