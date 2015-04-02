class StaticPagesController < ApplicationController
	def home
		if signed_in?
	      	@micropost  = current_user.microposts.build
	      	@feed_items = current_user.feed.page params[:page]
			respond_to do |format|
				format.html { render :layout => 'application' }
				format.rss { render :layout => false }
			end
	    end
	end

	def help
	end

	def about
	end

	def contact
	end
end
