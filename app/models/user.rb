class User < ActiveRecord::Base
	
	include PgSearch
  	
  	pg_search_scope :search_name_and_username,
		against: [:name, :username, :email],
		using: {
		  tsearch: { prefix: true, any_word: true }
	}

	VALID_EMAIL_REGEX ||= /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
	VALID_USERNAME_REGEX = /\A(\w|-|\.)+\z/i
	
	has_many :microposts, dependent: :destroy
	has_many :relationships, foreign_key: "follower_id", dependent: :destroy
	has_many :followed_users, through: :relationships, source: :followed
	has_many :reverse_relationships, foreign_key: "followed_id",
                                     class_name:  "Relationship",
                                     dependent:   :destroy
	# Chap 11: source: follower can be omitted, since Rails will infer a source
	# of :follower and hence look up follower_id in this case.
	has_many :followers, through: :reverse_relationships#, source: :follower
	has_many :replies, foreign_key: "to_id", 
	                   class_name: "Micropost"
	has_many :messages, foreign_key: "from"
	has_many :received_messages, foreign_key: "to", class_name: "Message"
	has_one :api_key
	before_create :create_remember_token, :create_email_verification_token
	# after_create :send_email_confirmation
	before_save { self.email.downcase! }
	validates :name, presence: true , length: {maximum: 50}
	validates :email, presence: true, format: {with: VALID_EMAIL_REGEX},
				      uniqueness: {case_sensitive: false}
    validates :password, length: {minimum: 6}
	has_secure_password
	validates :username, presence: true, length: { maximum: 15 }, 
	          format: { with: VALID_USERNAME_REGEX }, uniqueness: true

	def User.new_remember_token
		SecureRandom.urlsafe_base64
	end
	def User.encrypt(token)
		Digest::SHA1.hexdigest(token.to_s)
	end 

	def feed
		Micropost.where('user_id = ?', id)
	end

	def feed
		Micropost.feed_for_user(self)
	end

	def following?(other_user)
		relationships.find_by(followed_id: other_user.id)
	end

	def follow!(other_user)
		relationships.create!(followed_id: other_user.id)
	end

	def unfollow!(other_user)
		relationships.find_by(followed_id: other_user.id).destroy!
	end

	def send_follower_notification(follower)
		UserMailer.follower_notification(self, follower).deliver if notifications?
	end

	def send_password_reset
		update_attribute(:password_reset_token, User.new_remember_token)
		update_attribute(:password_reset_sent_at, Time.zone.now)
		UserMailer.password_reset(self).deliver
	end

	def invalidate_password_reset
		update_attribute(:password_reset_token, nil)
	end

	def self.search(query)
		if query.present?
			search_name_and_username(query)
		else
			where(nil)
		end
	end

	def send_email_confirmation
		UserMailer.email_confirmation(self).deliver
	end

	def send_registration_confirmation
		UserMailer.registration_confirmation(self).deliver
	end

	def set_active
		update_attribute(:active, true)
	end
	
	private
	  	
	  	def create_email_verification_token
			self.email_verification_token = User.new_remember_token
		end

	  	def create_remember_token
			self.remember_token = User.encrypt(User.new_remember_token)
		end

end
