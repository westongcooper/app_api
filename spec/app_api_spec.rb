require_relative '../app_api.rb'
require 'rspec'
require 'rack/test'
require 'sinatra'

describe 'app_api CRUD' do
  describe 'GET /appointments' do
    let(:response) { get '/appointments' }
    let(:json) { JSON.load(response.body) }

    it 'responds successfully' do
      expect(response.status).to eq 200
    end
    it 'returns all users' do
      expect(json.count).to eq(DB[:appts].all.count)
    end
  end
  context 'POST/GET/UPDATE/DELETE /appointments' do

    let(:response) { post '/appointments', Time_params.good }
    let(:post_id) { JSON.load(response.body)['id'] }

    it 'POSTS/Deletes VALID appointment' do
      expect(response.status).to eq 200
      apps_count = Appt.count
      delete "/appointments/#{post_id}"
      expect(Appt.count).to eq(apps_count - 1)
      expect(last_response.status).to eq 202
    end
    it 'POST FAILS with INVALID TIME appointment' do
      expect(response.status).to eq 200
      post '/appointments', Time_params.overlap
      expect(last_response.status).to eq 400
      delete "/appointments/#{post_id}"
    end
    it 'POST FAILS with OLD TIME appointment' do
      post '/appointments', Time_params.old
      expect(last_response.status).to eq 400
    end
    it 'GET /appointments/:id returns correct appointment' do
      expect(response.status).to eq 200
      get "/appointments/#{post_id}"
      expect(last_response.body).to include("#{post_id}")
      delete "/appointments/#{post_id}"
    end
    it 'PUT updates appointment' do
      expect(response.status).to eq 200
      put "/appointments/#{post_id}", Time_params.update
      expect(last_response.body).to include("#{post_id}", 'new', 'name')
      expect(last_response.status).to eq 202
      delete "/appointments/#{post_id}"
    end
    it 'PUT FAILS updates appointment with INVALID appointment' do
      expect(response.status).to eq 200
      post '/appointments', Time_params.good2
      put "/appointments/#{post_id}", Time_params.overlap
      expect(last_response.status).to eq 400
      delete "/appointments/#{post_id}"
      delete "/appointments/#{post_id-1}"
    end
    it 'PUT FAILS updates appointment with OLD appointment' do
      expect(response.status).to eq 200
      put "/appointments/#{post_id}", Time_params.old
      expect(last_response.status).to eq 400
      delete "/appointments/#{post_id}"
    end
    it 'GET returns only Scope from PARAMS' do
      expect(response.status).to eq 200
      post "/appointments", Time_params.good2
      post "/appointments", Time_params.good3
      scope = get '/appointments', Time_params.good.delete_if {|k,v| ![:start_time, :end_time].include?(k) }
      expect(scope.body).to eq  DB[:appts].where(:id => post_id).all.to_json
      delete "/appointments/#{post_id}"
      delete "/appointments/#{post_id+1}"
      delete "/appointments/#{post_id+2}"
    end
  end
end
