require_relative '../app_api.rb'
require 'rspec'
require 'rack/test'
require 'sinatra'


def json?(response)
  begin
    JSON.parse(response)
    return true
  rescue Exception
    false
  end
end

describe 'app_api' do
  it 'says Hello' do
    get '/'
    last_response.should be_ok
    expect(last_response.body).to include('Hello API')
  end
end

describe 'app_api /appointments' do
  it 'GET should return: status 200?' do
    get '/appointments'
    last_response.should be_ok
  end
  it 'GET should return valid JSON' do
    get '/appointments'
    expect(json?(last_response.body)).to be true
  end
end

describe 'app_api /appointments/:ID' do
  it 'GET should return: status 200?' do
    get '/appointments'
    last_response.should be_ok
  end
end
