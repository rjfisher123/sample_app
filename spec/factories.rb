FactoryGirl.define do

	sequence(:email) { |n| "person_#{n}@example.com"}
	
	factory :user do
		sequence(:name)  { |n| "Person #{n}" }
  		email { FactoryGirl.generate(:email) }
		password "foobar"
		password_confirmation "foobar"

		factory :admin do
      		admin true
  		end
	end 
	factory :micropost do
	    content "Lorem ipsum"
	    user
	end

	factory :message do 
		from 1
		to 2
		content "Just because I don't care doesn't mean I don't understand."
	end

	factory :userToReplyTo, class: User do | user |
		user.name "Reply T User"
		user.email "reply@user.com"
		user.password "foobar"
		user.password_confirmation "foobar"
	end
end