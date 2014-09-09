require 'spec_helper'

describe Message do
  let(:homer) { FactoryGirl.create(:user, name: 'Homer Simpson') }
  let(:bart) { FactoryGirl.create(:user, name: 'Bart Simpson') }
  let(:blah) { FactoryGirl.build(:message, from: homer.id, to: bart.id) }

  subject { blah }

  it { should respond_to(:from) }
  it { should respond_to(:to) }
  it { should respond_to(:content) }

  its(:sender) { should eq homer }
  its(:recipient) { should eq bart }

  describe "content cannot be blank" do 
  	before { blah.content = "" }
  	it { should_not be_valid }
  end

  describe "content cannot exceed 160 chars" do 
  	before { blah.content = "a" * 161 }
  	it { should_not be_valid }
  end

  describe "from cannot be blank" do 
  	before { blah.from = "" }
  	it { should_not be_valid }
  end

  describe "to must be a user id" do 
    before { blah.to = 'foo_bar'}
    it { should_not be_valid }
  end

end