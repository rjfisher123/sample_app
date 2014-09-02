class Micropost < ActiveRecord::Base
  # extend FriendlyId
  @@reply_to_regexp = /\A@([^\s]*)/
  @@direct_message_to_regexp = /\Ad ([^\s]*)/
  belongs_to :user
  belongs_to :to, class_name: "User"
  before_save :extract_in_reply_to 
  before_save :direct_message_to 
  validates :user_id, presence: true
  validates :content, presence: true, length: { maximum: 140 }

  default_scope -> { order('microposts.created_at DESC') }

  # Return microposts from the users being followed by the given user.
  # scope :from_users_followed_by, lambda { |user| followed_by(user) }
  # same, including replies.
  scope :from_users_followed_by_including_replies, lambda { |user| followed_by_including_replies(user) }
  # scope :get_replies, ->(user) { where({ to_id: user.id }) }
  private
    # def self.from_users_followed_by(user)
    #   followed_user_ids = "SELECT followed_id FROM relationships
    #                        WHERE follower_id = :user_id"
    #   where("user_id IN (#{followed_user_ids}) OR user_id = :user_id",
    #         user_id: user.id)
    # end

    def self.followed_by_including_replies(user)
      followed_ids = %(SELECT followed_id FROM relationships
                       WHERE follower_id = :user_id)
      # replied_ids = %(SELECT followed_id FROM microposts
                       # WHERE to_id = :user_id)
      where("user_id IN (#{followed_ids}) OR user_id = :user_id OR to_id = :user_id",
            user_id: user.id)
      # where("user_id IN (#{replied_ids})",
            # user_id: user.id)
    end

    def extract_in_reply_to
      if match = @@reply_to_regexp.match(content)
        user = User.find_by_slug(match[1])
        self.to = user if user
      end
    end

    def extract_direct_message_to
      if match = @@direct_message_to_regexp.match(content)
        user = User.find_by_slug(match[1])
        self.to = user if user
      end
    end

end