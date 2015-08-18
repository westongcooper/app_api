require_relative '../app_api.rb'
require 'rspec'
require 'rack/test'
require 'sinatra'

describe 'app_api' do

  it 'says Hello' do
    get '/'
    # last_response.should be_ok
    expect(last_response.body).to include('Hello API')
  end
end