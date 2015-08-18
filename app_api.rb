require 'sinatra/base'
require 'sinatra/sequel'
require 'pry'
require 'json'

all_dbs = Sequel.connect('postgres://westoncooper@localhost/app_api_development')
DB = all_dbs[:appt_api]

class AppApi < Sinatra::Application
  get '/' do
    'Hello API'
  end

  get '/appointments' do
    return DB.all.to_json
  end
  get '/appointments/:id' do
    DB.filter(id:params[:id]).first.to_json
  end
end