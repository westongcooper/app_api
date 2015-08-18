require 'sinatra/base'
require 'sinatra/sequel'
require 'pry'
require 'json'

DB = Sequel.connect('postgres://westoncooper@localhost/app_api_development')

class AppApi < Sinatra::Application
  get '/' do
    'Hello API'
  end

  get '/appointments' do
    return DB[:appt_api].all.to_json
  end
end