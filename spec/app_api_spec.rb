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
    end
    it 'POST FAILS with Duplicate TIME appointment' do
      expect(response.status).to eq 200
      post '/appointments', Time_params.good
      expect(last_response.status).to eq 400
    end
    it 'POST FAILS with OLD TIME appointment' do
      post '/appointments', Time_params.old
      expect(last_response.status).to eq 400
    end
    it 'GET /appointments/:id returns correct appointment' do
      expect(response.status).to eq 200
      get "/appointments/#{post_id}"
      expect(last_response.body).to include("#{post_id}")
    end
    it 'PUT updates appointment' do
      expect(response.status).to eq 200
      put "/appointments/#{post_id}", Time_params.update
      expect(last_response.body).to include("#{post_id}", 'new', 'name')
      expect(last_response.status).to eq 202
    end
    it 'PUT FAILS updates appointment with INVALID appointment' do
      expect(response.status).to eq 200
      post '/appointments', Time_params.good2
      put "/appointments/#{post_id}", Time_params.overlap
      expect(last_response.status).to eq 400
    end
    it 'PUT FAILS updates appointment with OLD appointment' do
      expect(response.status).to eq 200
      put "/appointments/#{post_id}", Time_params.old
      expect(last_response.status).to eq 400
    end
    it 'GET returns only Scope from PARAMS' do
      expect(response.status).to eq 200
      post "/appointments", Time_params.good2
      post "/appointments", Time_params.good3
      scope = get '/appointments', Time_params.good.delete_if {|k,v| ![:start_time, :end_time].include?(k) }
      expect(scope.body).to eq  DB[:appts].where(:id => post_id).all.to_json
    end
  end
end

describe 'app_api model validations' do
  it 'is valid with valid time' do
    expect(build(:appt)).to be_valid
  end
  it 'is invalid with same time' do
    appt = build(:appt)
    appt.save
    expect(build(:appt)).not_to be_valid
  end
  it 'is invalid with old time' do
    expect(build(:appt,
                 start_time:new_time(2014,10),
                 end_time:new_time(2014,20))).
      not_to be_valid
  end

  it 'is valid with bottom outside touch time' do
    appt = build(:appt,
                 start_time:new_time(2016,10),
                 end_time:new_time(2016,20))
    appt.save
    expect(build(:appt,
                 start_time:new_time(2016,1),
                 end_time:new_time(2016,9))).
      to be_valid
  end
  it 'is valid with bottom start_time end_time match' do
    appt = build(:appt,
                 start_time:new_time(2016,10),
                 end_time:new_time(2016,20))
    appt.save
    expect(build(:appt,
                 start_time:new_time(2016,1),
                 end_time:new_time(2016,10))).
      to be_valid
  end
  it 'is invalid with bottom overlap time' do
    appt = build(:appt,
                 start_time:new_time(2016,10),
                 end_time:new_time(2016,20))
    appt.save
    expect(build(:appt,
                 start_time:new_time(2016,1),
                 end_time:new_time(2016,11))).
      not_to be_valid
  end
  it 'is invalid with inside bottom touch time' do
    appt = build(:appt,
                 start_time:new_time(2016,10),
                 end_time:new_time(2016,20))
    appt.save
    expect(build(:appt,
                 start_time:new_time(2016,10),
                 end_time:new_time(2016,11))).
      not_to be_valid
  end
  it 'is invalid with inside time' do
    appt = build(:appt,
                 start_time:new_time(2016,10),
                 end_time:new_time(2016,20))
    appt.save
    expect(build(:appt,
                 start_time:new_time(2016,11),
                 end_time:new_time(2016,19))).
      not_to be_valid
  end
  it 'is invalid with inside top touch time' do
    appt = build(:appt,
                 start_time:new_time(2016,10),
                 end_time:new_time(2016,20))
    appt.save
    expect(build(:appt,
                 start_time:new_time(2016,19),
                 end_time:new_time(2016,20))).
      not_to be_valid
  end
  it 'is invalid with top outside time' do
    appt = build(:appt,
                 start_time:new_time(2016,10),
                 end_time:new_time(2016,20))
    appt.save
    expect(build(:appt,
                 start_time:new_time(2016,19),
                 end_time:new_time(2016,21))).
      not_to be_valid
  end
  it 'is valid with top end_time start_time match' do
    appt = build(:appt,
                 start_time:new_time(2016,10),
                 end_time:new_time(2016,20))
    appt.save
    expect(build(:appt,
                 start_time:new_time(2016,20),
                 end_time:new_time(2016,25))).
      to be_valid
  end
  it 'is valid with top not touching' do
    appt = build(:appt,
                 start_time:new_time(2016,10),
                 end_time:new_time(2016,20))
    appt.save
    expect(build(:appt,
                 start_time:new_time(2016,21),
                 end_time:new_time(2016,25))).
      to be_valid
  end

  it 'is invalid with surround time' do
    appt = build(:appt,
                 start_time:new_time(2016,10),
                 end_time:new_time(2016,20))
    appt.save
    expect(build(:appt,
                 start_time:new_time(2016,9),
                 end_time:new_time(2016,21))).
      not_to be_valid
  end
end

describe 'Param tests' do


end
