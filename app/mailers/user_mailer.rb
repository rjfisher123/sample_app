class UserMailer < ActionMailer::Base
	default :from => "rjfisher1@gmail.com"

	def registration_confirmation(user)
		@user = user
		attachments["rails.png"] = File.read("#{Rails.root}/app/assets/images/rails.png")
		mail(:to => "#{user.name} <#{user.email}>", :subject => "Registered")
	end

	def follower_notification(followed, follower)
		@followed = followed 
		@follower = follower
		mail(to: "#{followed.name} <#{followed.email}>", 
			subject: "You have a new follower")
	end

	def password_reset(user)
		@user = user 
		mail(to: "#{user.name} <#{user.email}>", subject: 'Password reset')
	end
end