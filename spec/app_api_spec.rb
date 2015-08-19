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

describe 'app_api /appointments' do
  it 'GET should return: status 200' do
    get '/appointments'
    expect(last_response.status).to eq(200)
  end
  it 'GET should return valid JSON' do
    get '/appointments'
    expect(json?(last_response.body)).to be true
  end
  # it 'POST should return: status 202.' do
  #   post 'appointments/999'
  # end
end

describe 'app_api /appointments/:ID' do
  it 'GET should return: :ID in response.body' do
    get '/appointments/20'
    expect(last_response.status).to eq(200)
    expect(json?(last_response.body)).to be true
    expect(last_response.body).to include(':20')
  end
  # it 'POST should return: status 202.' do
  #   delete '/appointments/999'
  #   puts last_response.body
  #   expect(last_response.status).to eq(202)
  # end
end


