require 'rails_helper'

include Helpers

RSpec.describe DatasetsController do
  before(:each) { 
    user = User.create(username: 'test@test.com', password: "password", password_confirmation: "password")
    sign_in user
  }

  describe 'upload' do
    context "invalid params" do
      it "returns 400 when invalid file" do
        post :upload, :params => { :file => {} }
        expect(response).to have_http_status(400)
      end

      it "returns 400 when url without name" do
        post :upload, :params => { :url => "sheetUrl" }
        expect(response).to have_http_status(400)
      end

      it "returns 400 when name without url" do
        post :upload, :params => { :name => "filename" }
        expect(response).to have_http_status(400)
      end

      it "returns 400 when url is not Google Sheet format compliant" do
        post :upload, :params => { :url => "invalidUrl", :name => "filename" }
        expect(response).to have_http_status(400)
      end
    end
  end
end
