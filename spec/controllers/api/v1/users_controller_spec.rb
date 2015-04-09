require 'spec_helper'

module Api
  module V1
    describe UsersController do
      render_views

      before { request.accept = "application/json" }

      describe 'POST #create' do
        let(:homer) { build(:user, name: 'Homer Simpson') }
        let(:json) do
          { format: 'json', user: { name: homer.name, username: homer.username,
              email: homer.email, password: homer.password,
              password_confirmation: homer.password } }
        end

        it "should create" do
          expect { post :create, json }.to change(User, :count).by(1)
          expect(response.status).to eq 201
          body = JSON.parse(response.body)
          expect(body['id']).to eq User.last.id
          expect(body['email']).to eq homer.email
        end
      end

      describe 'GET #index' do
        before { 3.times{ create(:user) } }
        describe 'without token' do

          it "should return 401 unauthorized" do
            get :index
            expect(response.status).to eq 401
          end
        end

        describe 'with token' do
          let(:homer) { create(:user, name: 'Homer Simpson') }

          before { homer.create_api_key! }

          it "should return user index" do
            set_http_authorization_header(homer)
            get :index
            expect(response.status).to eq 200
            # should list homer and 3 created users
            body_length = JSON.parse(response.body).length
            expect(body_length).to eq 4
          end
        end
      end

      describe 'GET #show' do
        let!(:santa) { create(:user, name: 'Santas little helper') }

        it "should show a single user to anybody" do
          get :show, id: santa
          expect(response.status).to eq 200
          body = JSON.parse(response.body)
          expect(body['id']).to eq santa.id
          expect(body['email']).to eq santa.email
        end
      end

      describe 'PATCH #update' do
        let(:bart) { create(:user, name: 'Bart Simpson') }
        let(:marge) { create(:user, name: 'Marge Simpson') }

        before do
          bart.create_api_key
          marge.create_api_key
        end

        it "should not let anonymous request update marge's particulars" do
          patch :update, id: marge, user: { email: 'new@for.marge.com' }
          expect(response.status).to eq 401
        end

        it "should not let bart update marge's particulars" do
          set_http_authorization_header(bart)
          patch :update, id: marge, user: { email: 'new@for.marge.com' }
          expect(response.status).to eq 401
        end

        it "should let marge update her particulars" do
          set_http_authorization_header(marge)
          patch :update, id: marge, user: { email: 'new@for.marge.com' }
          expect(response.status).to eq 200
          expect(JSON.parse(response.body)['email']).to eq 'new@for.marge.com'
        end
      end


      describe 'DELETE #destroy' do
        let(:bart) { create(:user, name: 'Bart Simpson') }
        let!(:marge) { create(:user, name: 'Marge Simpson') }
        let(:admin) { create(:admin) }

        before do
          bart.create_api_key
          admin.create_api_key
        end

        it "should not let anonymous users delete users" do
          delete :destroy, id: marge
          expect(response.status).to eq 401
        end

        it "should not let bart delete marge" do
          set_http_authorization_header(bart)
          delete :destroy, id: marge
          expect(response.status).to eq 401
        end

        it "should let admin delete a user" do
          set_http_authorization_header(admin)
          expect { delete :destroy, id: marge }.to change(User, :count).by(-1)
          expect(response.status).to eq 200
        end
      end


      describe 'GET #following' do
        let(:homer) { create(:user, name: 'Homer Simpson') }
        let(:marge) { create(:user, name: 'Marge Simpson') }
        let(:bart) { create(:user, name: 'Bart Simpson') }

        before do
          homer.create_api_key
          bart.follow!(marge)
          bart.follow!(homer)
        end

        it "should not let anonymous users retrieve list of following" do
          get :following, id: bart
          expect(response.status).to eq 401
        end

        it "should display list of following" do
          set_http_authorization_header(homer)
          get :following, id: bart
          expect(response.status).to eq 200
          expect(JSON.parse(response.body).length).to eq 2
        end
      end


      describe 'GET #followers' do
        let(:homer) { create(:user, name: 'Homer Simpson') }
        let(:marge) { create(:user, name: 'Marge Simpson') }
        let(:bart) { create(:user, name: 'Bart Simpson') }

        before do
          homer.create_api_key
          marge.follow!(bart)
          homer.follow!(bart)
        end

        it "should not let anonymous users retrieve list of followers" do
          get :followers, id: bart
          expect(response.status).to eq 401
        end

        it "should display list of followers" do
          set_http_authorization_header(homer)
          get :followers, id: bart
          expect(response.status).to eq 200
          expect(JSON.parse(response.body).length).to eq 2
        end
      end


      describe 'GET #feed' do
        let(:homer) { create(:user, name: 'Homer Simpson') }
        let(:marge) { create(:user, name: 'Marge Simpson') }
        let(:bart) { create(:user, name: 'Bart Simpson') }

        before do
          bart.create_api_key
          bart.follow!(homer)
          bart.follow!(marge)
          create :micropost, user: homer
          create :micropost, user: marge
          create :micropost, user: bart
        end

        it "should return 404 if no auth header is sent" do
          get :feed
          expect(response.status).to eq 401
        end

        it "should return posts from self and followed users" do
          set_http_authorization_header(bart)
          get :feed
          expect(response.status).to eq 200
          body = JSON.parse(response.body)
          expect(body.length).to eq 3
          expect(body[2]['user_id']).to eq homer.id
          expect(body[1]['user_id']).to eq marge.id
          expect(body[0]['user_id']).to eq bart.id
        end
      end
    end
  end
end
