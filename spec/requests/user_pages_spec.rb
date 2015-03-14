require 'spec_helper'

describe "User pages" do
  
  let(:user) { create(:user) }
  subject { page }
  
  describe "signup page" do
    before { visit signup_path }
    it { should have_content('Sign up') }
    it { should have_title(full_title('Sign up')) }
  end
 
  describe "signup" do

    before { visit signup_path }
    
    let(:submit) { "Create my account" }

    describe "with invalid information" do
      it "should not create a user" do
        expect { click_button submit }.not_to change(User, :count)
      end
    end

    describe "with valid information" do
      before { valid_signup }

      it "should create a user" do
        expect { click_button submit }.to change(User, :count).by(1)
      end

      describe "after saving the user" do
        before { click_button submit }
        let (:user) { User.find_by_email 'user@example.com' }

        it { should have_title user.name }
        it { should have_selector('div.alert.alert-success', text: 'Welcome') }
        it { should have_link 'Sign out' }
      end
    end
  end

  describe "edit" do
    let(:user) {FactoryGirl.create(:user)}
    before do
      sign_in user
      visit edit_user_path(user)
    end

    describe "page" do
      it {should have_content("Update your profile")}
      it {should have_title("Edit user")}
      it {should have_link('change', href: 'http://gravatar.com/emails')}
    end

    describe "with invalid information" do
      before { click_button "Save changes" }
      it { should have_content('error') }
    end

    describe "with valid information" do
      let(:new_name)  { "New Name" }
      let(:new_email) { "new@example.com" }
      before do
        fill_in "Name",             with: new_name
        fill_in "Email",            with: new_email
        fill_in "Password",         with: user.password
        fill_in "Confirm Password", with: user.password
        click_button "Save changes"
      end

      it { should have_title(new_name) }
      it { should have_selector('div.alert.alert-success') }
      it { should have_link('Sign out', href: signout_path) }
      specify { expect(user.reload.name).to  eq new_name }
      specify { expect(user.reload.email).to eq new_email }
    end
    
    describe "forbidden attributes" do
      let(:params) do
        { user: { admin: true, password: user.password,
        password_confirmation: user.password } }
      end 
      before do
        sign_in user, no_capybara: true
        patch user_path(user), params
      end
      specify { expect(user.reload).not_to be_admin }
    end
  end

  describe "index" do
    # let(:user) { FactoryGirl.create(:user) }
    before(:each) do
      sign_in user
      visit users_path
    end
    
    it { should have_title('All users') }
    it { should have_content('All users') }
    
    describe "pagination" do
      before(:all) { 30.times { FactoryGirl.create(:user) } }
      after(:all)  { User.delete_all }
      it { should have_selector('ul.users') }
      it "should list each user" do
        User.paginate(page: 1).each do |user|
          expect(page).to have_selector('li', text: user.username)
        end
      end 
    end

    describe "delete links" do

      it { should_not have_link('delete') }
      
      describe "as an admin user" do
        let(:admin) { FactoryGirl.create(:admin) }
        before do
          sign_out
          sign_in admin
          visit users_path
        end

        it { should have_link('delete', href: user_path(User.first)) }
        it "should be able to delete another user" do
          expect do
            click_link('delete', match: :first)
          end.to change(User, :count).by(-1)
        end
        it { should_not have_link('delete', href: user_path(admin)) }
      end
    end

  describe "should return a search of users" do
    before do
      query = User.first.name[0..2]
      fill_in 'query', with: query
      click_button 'Search'
    end
    it { should have_content User.first.username }
  end
  end

  describe "profile page" do
    let(:user) { FactoryGirl.create(:user) }
    let!(:m1) { FactoryGirl.create(:micropost, user: user, content: "Foo") }
    let!(:m2) { FactoryGirl.create(:micropost, user: user, content: "Bar") }
    
    before { visit user_path(user) }
    
    it { should have_content(user.name) }
    it { should have_title(user.name) }
    
    describe "microposts" do
      it { should have_content(m1.content) }
      it { should have_content(m2.content) }
      it { should have_content(user.microposts.count) }
    end
    
    describe "follow/unfollow buttons" do
      let(:other_user) { FactoryGirl.create(:user) }
      before { sign_in user }

      describe "following a user" do
        before { visit user_path(other_user) }

        it "should increment the followed user count" do
          expect do
            click_button "Follow"
          end.to change(user.followed_users, :count).by(1)
        end

        it "should increment the other user's followers count" do
          expect do
            click_button "Follow"
          end.to change(other_user.followers, :count).by(1)
        end

        describe "toggling the button" do
          before { click_button "Follow" }
          it { should have_xpath("//input[@value='Unfollow']") }
        end

        describe "should send follower notification to followed user" do 
          before { click_button "Follow" }
          specify { expect(ActionMailer::Base.deliveries.last.to).to eq [other_user.email] }
        end

        describe "should not send follower if notifications is set to false" do 
          before { other_user.update_attribute(:notifications, false) }
          specify do 
            expect{ click_button "Follow" }.not_to change(ActionMailer::Base.deliveries, :count).by(1)
          end       
        end
      end

      describe "unfollowing a user" do
        before do
          user.follow!(other_user)
          visit user_path(other_user)
        end

        it "should decrement the followed user count" do
          expect do
            click_button "Unfollow"
          end.to change(user.followed_users, :count).by(-1)
        end

        it "should decrement the other user's followers count" do
          expect do
            click_button "Unfollow"
          end.to change(other_user.followers, :count).by(-1)
        end

        describe "toggling the button" do
          before { click_button "Unfollow" }
          it { should have_xpath("//input[@value='Follow']") }
        end
      end
    end
  end

  describe "other users pages" do
    let(:user_me) { FactoryGirl.create(:user) }
    let(:user_other) { FactoryGirl.create(:user) }
    let!(:m1) { FactoryGirl.create(:micropost, user: user_other, content: "Foo") }
    before do
      sign_in user_me
      visit user_path(user_other)
    end

    describe "delete links" do
      it { should_not have_link('delete') }
    end
  end

  describe "following/followers" do
    let(:user) { FactoryGirl.create(:user) }
    let(:other_user) { FactoryGirl.create(:user) }
    before { user.follow!(other_user) }
    
    describe "followed users" do
      before do
        sign_in user
        visit following_user_path(user)
      end

      it { should have_title(full_title('Following')) }
      it { should have_selector('h3', text: 'Following') }
      it { should have_link(other_user.name, href: user_path(other_user)) }
      it { should have_link("1 following", href: following_user_path(user)) }
      it { should have_link("0 followers", href: followers_user_path(user)) }
    end
    describe "followers" do
      before do
        sign_in other_user
        visit followers_user_path(other_user)
      end

      it { should have_title(full_title('Followers')) }
      it { should have_selector('h3', text: 'Followers') }
      it { should have_link(user.name, href: user_path(user)) }
      it { should have_link("0 following", href: following_user_path(other_user)) }
      it { should have_link("1 followers", href: followers_user_path(other_user)) }
    end 
  end
end

# require 'spec_helper'

# describe "UserPages" do
#   # Chap 7.8, using FactoryGirl's syntax to create a user from the definition
#   # in /spec/factories.rb
#   #
#   let(:user) { create(:user) }

#   subject { page }

#   describe "Sign up" do
#     let(:submit) { "Create my account" }
#     before { visit signup_path }
#     # Ex 5.6.1 Using Capybara's have_selector
#     it { should have_selector('h1', text: 'Sign up') }
#     it { should have_title(full_title('Sign up')) }

#     describe "with invalid information" do
#       it "should not sign up a user" do
#         expect { click_button submit }.not_to change(User, :count)
#       end
#       # Ex 7.6.2 Test error messages for user sign-up.
#       describe "should display errors" do
#         before { click_button submit }
#         it { should have_title(full_title('Sign up')) }
#         it { should have_selector('div#error_explanation', text: 'error') }
#       end
#     end

#     describe "with valid information" do
#       let(:sign_up) do
#         fill_in "Name", with: "Foo Bar"
#         fill_in "Email", with: "foo@bar.com"
#         # fill_in "Username", with: "foo_bar"
#         fill_in "Password", with: "password"
#         fill_in "Confirm Password", with: "password"
#         click_button submit
#       end
#       it "should sign up a new user" do
#         expect { sign_up }.to change(User, :count).by(1)
#       end
#       # Ex 7.6.3 Test post user creation.
#       describe "after creating the user" do
#         before { sign_up }
#         it { should have_title('Foo Bar') }
#         it { should have_selector('div.alert.alert-success', text: 'Welcome') }
#         it { should have_link('Sign out') }
#       end
#     end
#   end


#   describe "Profile (show user) page" do
#     describe "for unauthenticated users" do
#       before { visit user_path user }
#       it { should have_title(user.name) }
#       it { should have_selector('h1', text: user.name) }
#     end

#     describe "follow/unfollow buttons" do
#       let(:other_user) { create(:user) }
#       before { sign_in user }

#       describe "following a user" do
#         before { visit user_path(other_user) }

#         it "should increment the followed user count" do
#           expect do
#             click_button "Follow"
#           end.to change(user.followed_users, :count).by(1)
#         end

#         it "should increment the other user's followers count" do
#           expect do
#             click_button "Follow"
#           end.to change(other_user.followers, :count).by(1)
#         end

#         describe "toggling the button" do
#           before { click_button "Follow" }
#           it { should have_xpath("//input[@value='Unfollow']") }
#         end

#         describe "should send follower notification to followed user" do
#           before { click_button "Follow" }
#           specify { expect(ActionMailer::Base.deliveries.last.to).to eq [other_user.email] }
#         end

#         describe "should not send follower if notifications is set to false" do
#           before { other_user.update_attribute(:notifications, false) }
#           specify do
#             expect{ click_button "Follow" }.not_to change(ActionMailer::Base.deliveries, :count).by(1)
#           end
#         end
#       end

#       describe "unfollowing a user" do
#         before do
#           user.follow!(other_user)
#           visit user_path(other_user)
#         end

#         it "should decrement the followed user count" do
#           expect do
#             click_button "Unfollow"
#           end.to change(other_user.followers, :count).by(-1)
#         end

#         it "should decrement the other user's followers count" do
#           expect do
#             click_button "Unfollow"
#           end.to change(other_user.followers, :count).by(-1)
#         end

#         describe "toggling the button" do
#           before { click_button "Unfollow" }
#           it { should have_xpath("//input[@value='Follow']") }
#         end
#       end
#     end
#   end


#   describe "User stats on profile page" do
#     let(:skinner) { create(:user, name: "Seymour Skinner") }
#     let(:edna) { create(:user, name: "Edna Krabappel") }
#     let(:lisa) { create(:user, name: "Lisa Simpson") }

#     before do
#       lisa.follow!(skinner)
#       lisa.follow!(edna)
#     end

#     describe "skinner's stats" do
#       before { visit user_url(skinner) }
#       it { should have_content('0 following') }
#       it { should have_content('1 follower')}
#     end

#     describe "edna's stats" do
#       before { visit user_url(edna) }
#       it { should have_content('0 following') }
#       it { should have_content('1 follower')}
#     end

#     describe "lisa's stats" do
#       before { visit user_url(lisa) }
#       it { should have_content('2 following') }
#       it { should have_content('0 followers')}
#     end
#   end


#   describe "Settings (edit user) page" do
#     before do
#       sign_in user
#       visit edit_user_path(user)
#     end
#     it { should have_content('Update your profile') }
#     it { should have_title('Edit user') }
#     it { should have_link('change', href: 'http://gravatar.com/emails') }

#     describe "updating with invalid information" do
#       before { click_button "Save changes" }
#       it { should have_error_message }
#     end

#     describe "updating with valid information" do
#       let(:marge) { build(:user, name: 'Marge Simpson') }
#       before do
#         fill_in "Name", with: marge.name
#         fill_in "Email", with: marge.email
#         # fill_in "Username", with: marge.username
#         fill_in "Password", with: marge.password
#         fill_in "Confirm Password", with: marge.password
#         click_button 'Save changes'
#       end
#       it { should have_title(marge.name) }
#       it { should have_selector('div.alert.alert-success') }
#       it { should have_link('Sign out', href: signout_path) }
#       specify { expect(user.reload.name).to eq marge.name }
#       specify { expect(user.reload.email).to eq marge.email }
#     end
#   end

#   describe "Index page" do
#     before do
#       sign_in user
#       visit users_path
#     end
#     it { should have_title('All users') }
#     it { should have_selector('h1', 'All users') }

#     describe "pagination of users" do
#       # Chap 9.31 before(:all) and after(:all) ensure these functions are carried
#       # out only once for all tests in the block (an optimization for speed).
#       #
#       before(:all) { 30.times { create(:user) } }
#       after(:all) { User.delete_all }

#       # test that the will_paginate gem is in force
#       # it { should have_selector('div.pagination') }

#       # it "should list each user" do
#       #   User.paginate(page: 1).each do |u|
#       #     expect(page).to have_selector('li', text: u.name)
#       #   end
#       # end

#       # test that the kaminari gem is in force
#       it { should have_selector('ul.pagination') }

#       it "should list each user" do
#         User.page(1).each do |u|
#           expect(page).to have_selector('li', text: u.name)
#         end
#       end
#     end

#     it "should not have delete links for non administrators" do
#       expect(page).not_to have_link('delete')
#     end

#     describe "should return a search of users" do
#       before do
#         query = User.first.name[0..2]
#         fill_in 'query', with: query
#         click_button 'Search'
#       end
#       it { should have_content User.first.username }
#     end
#   end

#   describe "Following and follower pages" do
#     let(:homer) { create(:user, name: 'Homer Simpson') }
#     let(:marge) { create(:user, name: 'Marge Simpson') }
#     before { marge.follow!(homer) }

#     describe "followed users" do
#       before do
#         sign_in marge
#         visit following_user_path(marge)
#       end
#       it { should have_title(full_title('Following')) }
#       it { should have_selector('h3', text: 'Following') }
#       it { should have_link(homer.name, href: user_path(homer)) }
#     end

#     describe "followers" do
#       before do
#         sign_in homer
#         visit followers_user_path(homer)
#       end
#       it { should have_title(full_title('Followers')) }
#       it { should have_selector('h3', text: 'Followers') }
#       it { should have_link(marge.name, href: user_path(marge)) }
#     end
#   end
# end

