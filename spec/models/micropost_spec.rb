require 'spec_helper'
describe Micropost do
	
	let(:user) { FactoryGirl.create(:user) }
	before { @micropost = user.microposts.build(content: "Lorem ipsum") }
	
	subject { @micropost }
	
	it { should respond_to(:content) }
	it { should respond_to(:user_id) }
	it { should respond_to(:user) }
	it { should respond_to(:to) }
	its(:user) { should eq user }
	it { should be_valid }
	
	describe "when user_id is not present" do
		before { @micropost.user_id = nil }
		it { should_not be_valid }
	end

	describe "with blank content" do
	    before { @micropost.content = " " }
	    it { should_not be_valid }
  	end

  	describe "with content that is too long" do
  		before { @micropost.content = "a" * 141 }
    	it { should_not be_valid }
	end

	describe "from_users_followed_by_including_replies" do

		before(:each) do
			@other_user = FactoryGirl.create(:user, email: FactoryGirl.generate(:email))
			@third_user = FactoryGirl.create(:user, email: FactoryGirl.generate(:email))

			@user_post  = user.microposts.create!(content: "foo")
			@other_post = @other_user.microposts.create!(content: "bar")
			@third_post = @third_user.microposts.create!(content: "baz")

			@userToReplyTo = FactoryGirl.create(:userToReplyTo)
			@forth_post = @third_user.microposts.create!(content: "@reply-t-user baz")			
			
			user.follow!(@other_user)
		end

		it "should have a from_users_followed_by class method" do
			expect(Micropost).to respond_to(:from_users_followed_by_including_replies)
		end

		it "should include the followed user's microposts" do
			expect(Micropost.from_users_followed_by_including_replies(user)).to include(@other_post)
		end

		it "should include the user's own microposts" do
			expect(Micropost.from_users_followed_by_including_replies(user)).to include(@user_post)
		end

		it "should not include an unfollowed user's microposts" do
			expect(Micropost.from_users_followed_by_including_replies(user)).not_to eq include(@third_post)
		end

		it "should include posts to user" do
			expect(Micropost.from_users_followed_by_including_replies(@userToReplyTo)).to include(@forth_post)
		end
	end
  
	describe "replies" do
		before(:each) do
			@reply_to_user = FactoryGirl.create(:userToReplyTo)
			@micropost = user.microposts.create(content: "@reply-t-user Look a reply to Reply T User")
		end
		it "should identify a @user and set the to_id field accordingly" do
			expect(@micropost.to).to eq @reply_to_user 
		end

	end
end 