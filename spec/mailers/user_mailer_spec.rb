# http://blog.lucascaton.com.br/index.php/2010/10/25/how-to-test-mailers-in-rails-3-with-rspec/
require "spec_helper"

describe UserMailer do
  
	describe 'follower_notification' do 
		let(:patty)  { FactoryGirl.create(:user, name: 'Patty Bouvier') }
		let(:selma) { FactoryGirl.create(:user, name: 'Selma Bouvier') }
		let(:mail) { patty.send_follower_notification(selma) }

		subject { mail }

		# expect(page).to have_selector('li', text: user.name)

		it 'renders the subject' do 
			expect(mail.subject).to match('new follower')
		end

		it 'renders the receiver email' do 
			expect(mail.to).to eq([patty.email])
		end

		it 'renders the sender email' do 
			expect(mail.from).to eq(['rjfisher1@gmail.com'])
		end

		it 'assigns @followed' do 
			expect(mail.body.encoded).to match(patty.name)
		end

		it 'assigns @follower' do 
			expect(mail.body.encoded).to match(selma.name)
		end
	end

	describe 'registration confirmation' do

		let(:user) { FactoryGirl.create(:user) }
		let(:mail) { UserMailer.registration_confirmation(user) }

		it 'renders the subject' do
		  expect(mail.subject).to eq('Registered')
		end

		it 'renders the receiver email' do
		  expect(mail.to).to eq([user.email])
		end

		it 'renders the sender email' do
		  expect(mail.from).to eq(['rjfisher1@gmail.com'])
		end

		it 'assigns @name' do
		  expect(mail.body.encoded).to match(user.name)
		end

		it 'assigns @confirmation_url' do
		  expect(mail.body.encoded).to match("http://localhost:3000/users/#{user.slug}/edit")
		end
	end

	describe 'password_reset' do 
		let(:blinky) { FactoryGirl.create(:user, name: 'Blinky Three Eye') }
		let(:mail) { blinky.send_password_reset }

		subject { mail }

		it 'renders the subject' do 
			expect(mail.subject).to match('Password reset')
		end

		it 'renders the receiver email' do 
			expect(mail.to).to eq([blinky.email])
		end

		it 'renders the sender email' do 
			expect(mail.from).to eq(['rjfisher1@gmail.com'])
		end

		it 'assigns @user' do 
			expect(mail.body.encoded).to match(blinky.name)
		end
	end
end