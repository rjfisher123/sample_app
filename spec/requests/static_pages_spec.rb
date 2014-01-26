require 'spec_helper'

describe "StaticPages" do
  describe "Home page" do
    it "should have content 'Sample App'" do
      visit '/static_pages/home'
      expect(page).to have_content('Sample App')
    end

    it "should have the right title 'Home" do
	  visit '/static_pages/home'
  	  expect(page).to have_title("Ruby on Rails Tutorial Sample App | Home")
  	end
end

  end
describe "Help page" do
    it "should have content 'Help'" do
      visit '/static_pages/help'
      expect(page).to have_content('Help')
    end

    it "should have the right title 'Help" do
	  visit '/static_pages/help'
  	  expect(page).to have_title("Ruby on Rails Tutorial Sample App | Help")
  	end

end
  
describe "About page" do
    it "should have content 'About us'" do
      visit '/static_pages/about'
      expect(page).to have_content('About us')
    end

    it "should have the right title 'About us" do
	  visit '/static_pages/about'
  	  expect(page).to have_title("Ruby on Rails Tutorial Sample App | About us")
  	end

end
