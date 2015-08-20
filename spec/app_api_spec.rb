require_relative '../app_api.rb'
require 'rspec'
require 'rack/test'
require 'sinatra'

def json?(response)
  begin
    true if JSON.parse(response)
  rescue Exception
    false
  end
end

describe 'app_api' do
  it 'says Hello' do
    get '/'
    expect(last_response.status).to eq(200)
    expect(last_response.body).to include('Hello API')
  end
end
describe 'app_api CRUD' do
  describe 'GET /appointments' do
    before {get '/appointments'}
    let(:json) { JSON.load(last_response.body)}
    let(:appt) {json[:id]}

    it 'responds successfully' do
      expect(last_response.status).to eq 200
    end
    it 'returns all users' do
      expect(json.count).to eq(DB[:appts].all.count)
    end
  end
  context 'POST/GET/UPDATE/DELETE /appointments' do
    let(:response) { post '/appointments', Time_params.params_good }
    let(:post_id) { JSON.load(response.body)['id'] }
    it 'POSTS/Deletes VALID appointment' do
      expect(response.status).to eq(201)
      apps_count = Appt.count
      delete "/appointments/#{post_id}"
      expect(Appt.count).to eq(apps_count - 1)
      expect(last_response.status).to eq(202)
    end
    it 'POST FAILS with INVALID TIME appointment' do
      expect(response.status).to eq(201)
      post '/appointments', Time_params.params_overlap
      expect(last_response.status).to eq(400)
      delete "/appointments/#{post_id}"
    end
    it 'POST FAILS with OLD TIME appointment' do
      post '/appointments', Time_params.params_old
      expect(last_response.status).to eq(400)
    end
    it 'GET /appointments/:id returns correct appointment' do
      expect(response.status).to eq(201)
      get "/appointments/#{post_id}"
      expect(last_response.body).to include("#{post_id}")
      delete "/appointments/#{post_id}"
    end
    it 'PUT updates appointment' do
      expect(response.status).to eq(201)
      put "/appointments/#{post_id}", Time_params.update
      expect(last_response.body).to include("#{post_id}", 'new', 'name')
      delete "/appointments/#{post_id}"
    end
    it 'PUT FAILS updates appointment with INVALID appointment' do
      expect(response.status).to eq(201)
      post '/appointments', Time_params.params_good2
      put "/appointments/#{post_id}", Time_params.params_overlap
      expect(last_response.status).to eq(400)
      delete "/appointments/#{post_id}"
      delete "/appointments/#{post_id-1}"
    end
    it 'PUT FAILS updates appointment with OLD appointment' do
      expect(response.status).to eq(201)
      put "/appointments/#{post_id}", Time_params.params_old
      expect(last_response.status).to eq(400)
      delete "/appointments/#{post_id}"
    end
  end
end
