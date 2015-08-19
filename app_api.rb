require 'sinatra/base'
require 'sinatra/sequel'
require 'pry'
require 'json'

DB = Sequel.connect('postgres://westoncooper@localhost/app_api_development')
class Appt < Sequel::Model
  plugin :validation_helpers
  plugin :validation_class_methods
  set_primary_key [:id]
  def validate
    super
    validates_presence [:first_name, :last_name, :start_time, :end_time]
    validates_format /^[a-zA-Z]+$/, [:first_name, :last_name]
    validates_schema_types [:start_time,:end_time]
  end
  validates_each :start_time, :end_time do |object, attribute, value|
    object.errors.add(attribute, "invalid datetime") unless check_date(object, attribute, value)
  end
end

def check_date(object, attribute, value)
  begin
    value < Time.now ? (return false) : true
    object[:start_time] > object[:end_time] ? (return false) : true
    if attribute == :start_time
      b = Appt.where{(start_time >= object[:start_time]) & (start_time < object[:end_time])}
    else
      b = Appt.where{(end_time < object[:end_time]) & (end_time > object[:start_time])}
    end
    b.empty?
  rescue Exception
    false
  end
    # binding.pry
end

class AppApi < Sinatra::Application
  get '/' do
    'Hello API'
  end

  get '/appointments' do
    DB[:appts].all.to_json
    binding.pry
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