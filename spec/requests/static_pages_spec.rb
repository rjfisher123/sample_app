require 'spec_helper'
describe "Static pages" do
  subject {page}
  shared_examples_for "all static pages" do
    it {should have_selector('h1', text: heading)}
    it {should have_title(full_title(page_title))}
  end
  describe "Home page" do
    before {visit root_path}
    let (:heading) {'Sample App'}
    let (:page_title) {''}
    
    it_should_behave_like "all static pages"
    it {should_not have_title("| Home")}
    it "should have the right links on the layout" do
      visit root_path
      click_link "About"
      expect(page).to have_title(full_title('About us')) 
      click_link "Help"
      expect(page).to have_title(full_title('Help'))
      click_link "Contact"
      expect(page).to have_title(full_title('Contact'))
      click_link "Home" 
      click_link "Sign up now!" 
      expect(page).to have_title(full_title('Sign up'))
      click_link "sample app" 
      expect(page).to have_title(full_title(''))
    end
    describe "for signed-in users" do
      let(:user) { FactoryGirl.create(:user) }
      before do
        31.times { FactoryGirl.create(:micropost, user: user) }
        sign_in user
        visit root_path
      end

      after { user.microposts.delete_all }

      it "should render the user's feed" do
        user.feed[1..28].each do |item|
          should have_selector("li##{item.id}", text: item.content)
        end
      end

      it "should have micropost count and pluralize" do
        should have_content('31 microposts')
      end

      it "should paginate after 31" do
        should have_selector('div.pagination')
      end
    end
  end
  describe "Help page" do
    before {visit help_path}
    it {should have_selector('h1', text: 'Help')}
    it {should have_title(full_title('Help'))}
  end
  describe "About page" do
    before { visit about_path}
    it {should have_content('About us')}
    it {should  have_title(full_title('About us'))}
  end
  describe "Contact page" do
    before {visit contact_path}
    it {should have_content('Contact')}
    it {should have_title(full_title('Contact'))}
  end
end 