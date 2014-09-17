class User < ActiveRecord::Base
	
	include PgSearch
  	
  	pg_search_scope :search_name_and_slug,
		against: [:name, :slug, :email],
		using: {
		  tsearch: { prefix: true, any_word: true }
	}

	VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
	extend FriendlyId
  	friendly_id :name, use: [:slugged, :finders, :history]
	has_many :microposts, dependent: :destroy
	has_many :relationships, foreign_key: "follower_id", dependent: :destroy
	has_many :followed_users, through: :relationships, source: :followed
	has_many :reverse_relationships, foreign_key: "followed_id",
                                     class_name:  "Relationship",
                                     dependent:   :destroy
	has_many :followers, through: :reverse_relationships, source: :follower
	has_many :replies, foreign_key: "to_id", 
	                   class_name: "Micropost"
	has_many :messages, foreign_key: "from"
	has_many :received_messages, foreign_key: "to", class_name: "Message"
	before_create :create_remember_token
	before_save { self.email = email.downcase }
	validates :name, presence: true, length: {maximum: 50}
	validates :email, presence: true, format: {with: VALID_EMAIL_REGEX},
				      uniqueness: {case_sensitive: false}
    validates :password, length: {minimum: 6}
	has_secure_password

	def User.new_remember_token
		SecureRandom.urlsafe_base64
	end
	def User.encrypt(token)
		Digest::SHA1.hexdigest(token.to_s)
	end 

	def feed
		Micropost.from_users_followed_by_including_replies(self)
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
	
	def self.find_by_slug(slug_name)
		all = where(slug: slug_name)
		return nil if all.empty?
		all.first
	end

	def send_follower_notification(follower)
		UserMailer.follower_notification(self, follower).deliver if notifications?
	end

	# Friendly_Id code to only update the url for new records
	def should_generate_new_friendly_id?
		new_record? || slug.blank?
	end

	def send_password_reset
		token = SecureRandom.urlsafe_base64
		update_attribute(:password_reset_token, token)
		update_attribute(:password_reset_sent_at, Time.zone.now)
		UserMailer.password_reset(self).deliver
	end

	def invalidate_password_reset
		update_attribute(:password_reset_token, nil)
	end

	def self.search(query)
		if query.present?
			search_name_and_slug(query)
		else
			where(nil)
		end
	end
	
	private
	  	
	  	def create_remember_token
			self.remember_token = User.encrypt(User.new_remember_token)
		end

end
