require 'spec_helper'

describe User do

  before do
    @user = User.new(name: "Example User", email: "user@example.com",
                     username: "foo_bar", password: "foobar", password_confirmation: "foobar")
  end
  
  subject {@user}

  it {should be_valid }
  it {should respond_to(:email)}
  it {should respond_to(:name)}
  it {should respond_to(:password_digest)}
  it {should respond_to(:password)}
  it {should respond_to(:password_confirmation)}
  it {should respond_to(:remember_token) }
  it {should respond_to(:authenticate) }
  it {should respond_to(:admin) }
  it {should respond_to(:microposts) }
  it {should respond_to(:feed) }
  it {should respond_to(:relationships) }
  it {should respond_to(:followed_users) }
  it {should respond_to(:reverse_relationships) }
  it {should respond_to(:followers) }
  it {should respond_to(:username) }
  it {should respond_to(:following?) }
  it {should respond_to(:follow!) }
  it {should respond_to(:unfollow!) }
  it {should respond_to(:messages) }
  it {should respond_to(:received_messages) }
  it {should respond_to(:notifications) }
  it { should_not be_admin }

  describe "when name not present" do
  	before {@user.name = ""}
  	it {should_not be_valid}
  end

  describe "when name too long" do
  	before {@user.name = "a"*51}
  	it {should_not be_valid}
  end  

  describe "when email not present" do
  	before {@user.email = ""}
  	it {should_not be_valid}
  end

  describe "when email format is invalid" do
    it "should be invalid" do
      addresses = %w[user@foo,com user_at_foo.org example.user@foo.
                     foo@bar_baz.com foo@bar+baz.com foo@bar..com]
      addresses.each do |invalid_address|
        @user.email = invalid_address
        expect(@user).not_to be_valid
      end
    end
	end 
    
  describe "when email format is valid" do
    it "should be valid" do
      addresses = %w[user@foo.COM A_US-ER@f.b.org frst.lst@foo.jp a+b@baz.cn]
      addresses.each do |valid_address|
        @user.email = valid_address
        expect(@user).to be_valid
      end
    end 
  end

  describe "email address with mixed case" do
    let(:mixed_case_email) { "Foo@ExAMPle.CoM" }
    it "should be saved as all lower-case" do
      @user.email = mixed_case_email
      @user.save
      expect(@user.reload.email).to eq mixed_case_email.downcase
    end 
  end

  describe "when email address is already taken" do
    before do
      user_with_same_email = @user.dup
      user_with_same_email.email = @user.email.upcase
      user_with_same_email.save
    end
    
    it { should_not be_valid }
  end

  describe "when password is not present" do
    before do
    @user = User.new(name: "Example User", email: "user@example.com",
                     password: " ", password_confirmation: " ")
    end
    it { should_not be_valid }
  end

  describe "when password doesn't match confirmation" do
    before { @user.password_confirmation = "mismatch" }
    it { should_not be_valid }
  end
 
  describe "with a password that's too short" do
    before { @user.password = @user.password_confirmation = "a" * 5 }
    it { should be_invalid }
  end
  
  describe "return value of authenticate method" do
    before { @user.save }
    let(:found_user) { User.find_by(email: @user.email) }
     describe "with valid password" do
       it { should eq found_user.authenticate(@user.password) }
     end
     describe "with invalid password" do
       let(:user_for_invalid_password) { found_user.authenticate("invalid") }
       it { should_not eq user_for_invalid_password }
       specify { expect(user_for_invalid_password).to be_false }
     end
  end
  
  describe "remember token" do
    before { @user.save }
    its(:remember_token) { should_not be_blank }
  end

  describe "username validations" do
    let(:homer) { build(:user, name: 'Homer Simpson') }
    subject { homer }

    describe "when empty" do
      before { homer.username = "" }
      it { should_not be_valid }
    end
    describe "when too long" do
      before { homer.username = "a" * 16 }
      it { should_not be_valid }
    end
    describe "when not unique" do
      let(:copycat) { build(:user, username: homer.username) }
      before { homer.save! }
      specify { expect(copycat).not_to be_valid }
    end
    describe "when it contains invalid characters" do
      it "should be invalid" do
        invalid_usernames = ['!noexclaim', 'no space', '{"symbols']
        invalid_usernames.each do |e|
          homer.username = e
          expect(homer).not_to be_valid
        end
      end
    end
  end

  describe "with admin attribute set to 'true'" do
    before do
      @user.save!
      @user.toggle!(:admin)
    end

    it { should be_admin }
  end

  describe "micropost associations" do
    before do
      @user.save!
      @user.set_active
    end

    let!(:older_micropost) do
      FactoryGirl.create(:micropost, user: @user, created_at: 1.day.ago)
    end
    let!(:newer_micropost) do
      FactoryGirl.create(:micropost, user: @user, created_at: 1.hour.ago)
    end

    context "ordered by microposts.created_at DESC" do
      subject { @user.microposts }
      it { should == [newer_micropost, older_micropost] }
    end

    context "when user is destroyed" do
      subject { -> { @user.destroy } }
      it { should change(Micropost, :count).by(-2) }
    end

    describe "status" do
      let(:unfollowed_post) { FactoryGirl.create(:micropost, user: FactoryGirl.create(:user)) }
      let(:followed_user) { FactoryGirl.create(:user) }

      before do
        @user.follow!(followed_user)
        3.times { followed_user.microposts.create!(content: "Lorem Ipsum") }
      end

      its(:feed) { should include(newer_micropost) }
      its(:feed) { should include(older_micropost) }
      its(:feed) { should_not include(unfollowed_post) }
      its(:feed) do
        followed_user.microposts.each do |micropost|
          should include(micropost)
        end
      end
    end
  end

  describe "following" do
    let(:other_user) { FactoryGirl.create(:user) }
    before do
      @user.save
      @user.follow!(other_user)
    end

    it { should be_following(other_user) }
    its(:followed_users) { should include(other_user) }

    describe "followed user" do
      subject { other_user }
      its(:followers) { should include(@user) }
    end

    describe "and unfollowing" do
      before { @user.unfollow!(other_user) }

      it { should_not be_following(other_user) }
      its(:followed_users) { should_not include(other_user) }
    end

    describe "destroy user" do
      it "should destroy associated relationships" do
        @user.destroy
        expect(Relationship.where(follower_id: @user.id, followed_id: other_user.id)).to be_empty
      end
    end

    describe "destroy other_user" do
      it "should destroy associated relationships" do
        other_user.destroy
        expect(Relationship.where(follower_id: @user.id, followed_id: other_user.id)).to be_empty
      end
    end
  end

  # describe "handling replies" do
  #    before(:each) do
  #      @user = User.create!(name: "Example User", email: "user@example.com", active: true,
  #                    username: "exp-user", password: "foobar", password_confirmation: "foobar")
  #      @reply_to_user = FactoryGirl.create(:userToReplyTo)
  #      @user_with_strange_name = FactoryGirl.create(:user, email:FactoryGirl.generate(:email), 
  #                                username: "quack", name: "Quack van Duck")
  #    end

  #    it "should be findable by username name" do
  #      user = User.search("reply-t-user").first
  #      expect(user).to eq @reply_to_user
  #    end
   
  #    it "should scope replies to self" do
  #       m = @user.microposts.create!(content:"@reply-t-user from me")
  #       expect(m.to).to eq @reply_to_user.id
  #       expect(@reply_to_user.replies).to eq [m]   
  #    end
  # end

  describe "relationship associations" do
    let(:marge) { create(:user, name: 'Marge Simpson') }
    let(:homer) { create(:user, name: 'Homer Simpson') }

    before { marge.follow! homer }

    subject { marge }

    it { should be_following homer }
    its(:followed_users) { should include homer }

    describe "followed user" do
      subject { homer }
      its(:followers) { should include marge }
    end

    describe "and unfollowing" do
      before { marge.unfollow! homer }
      it { should_not be_following homer }
      its(:followed_users) { should_not include homer }
    end

    # Exercise 11.5.1 Tests for destroying asociated relationships
    it "should destroy relationships when a user is destroyed" do
      relationships = Relationship.where(follower_id: marge.to_param).to_a
      marge.destroy
      expect(relationships).not_to be_empty
      relationships.each do |r|
        expect(Relationship.where(id: r.id)).to be_empty
      end
    end
  end

  describe User do
    subject { create :user }
   
    it "sends an registration confirmation email" do
      expect { subject.send_registration_confirmation}.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end
end