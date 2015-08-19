require 'sinatra/base'
require 'sinatra/sequel'
require 'pry'
require 'json'

DB = Sequel.connect('postgres://westoncooper@localhost/app_api_development')
class Appt < Sequel::Model
  set_primary_key [:id]
end

def bad_date?(data)
  if  data['start_time'] < Date.today
    return false
  elsif data['end_time'] < data['start_time']
    return false
  end
  true
end

class AppApi < Sinatra::Application
  get '/' do
    'Hello API'
  end

  get '/appointments' do
    DB[:appts].all.to_json
  end
  post '/appointments' do
    strong_params = ['first_name', 'last_name', 'start_time', 'end_time', 'comments']
    data = params.select { |k, v| strong_params.include? k }
    if bad_date?(data)
      status 400
    else
      appt = DB.new(data)
      appt.save
    end
  end


  get '/appointments/:id' do
    Appt[:id].values.to_json
  end
  delete '/appointments/:id'do
    appt = Appt[:id]
    appt.nil? ? (return status 404) : appt.delete
    status 202
  end
end