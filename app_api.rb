require 'sinatra/base'
require 'sinatra/sequel'
require 'json'
require 'sinatra/contrib'

if ENV['RACK_ENV'] == 'test' #Connect to the database
  DB = Sequel.connect(:adapter=>'postgres',
                      :host=>'localhost',
                      :database=>'app_api_test',
                      :user=>'westoncooper')
else
  DB = Sequel.connect(adapter: 'postgresql',
                      host: '172.17.42.1',
                      database: 'app_api_development',
                      user: 'root',
                      port:'32771',
                      password: ENV['PG_password'])
end

class Appt < Sequel::Model #Sequel Model for appointments.
  plugin :validation_helpers
  plugin :validation_class_methods
  set_primary_key [:id]
  def validate
    super
    validates_presence [:first_name, :last_name, :start_time, :end_time]
    validates_format /^[a-z ,.'-]+$/i, [:first_name, :last_name]
    validates_format /^$|^[a-zA-Z0-9 .!?"-]+$/, :comments
    validates_schema_types [:start_time, :end_time]
  end
  validates_each :start_time, :end_time do |object, attribute, value| #sends The NEW 'appointment', the 'start_time' or 'end_time', and the 'time'
    object.errors.add(attribute, 'datetime overlap') if overlap_date?(object, attribute, value) #if overlap_date? true then return errors.
  end
  validates_each :start_time do |object, attribute, value|
    object.errors.add(attribute, 'invalid datetime') if invalid_dates?(object, value) #checks if NEW appointment start_time is > new end_time AND start_time != end_time
    object.errors.add(attribute, 'datetime overlap') if surround_date?(object)# checks current appointments and sees if NEW start_time is > each appointment start_time & < the same appt's end_time.
  end
end


class AppApi < Sinatra::Application
  register Sinatra::Contrib
  before /.*/ do #added to respond to .json extension
    if request.url.match(/.json$/)
      request.accept.unshift('application/json')
      request.path_info = request.path_info.gsub(/.json$/,'')
    end
  end

  get '/appointments' do
    begin
      if time_params? #if time params are passed in get command
        appts = find_appointments #find appointments in that time.
      else
        appts = DB[:appts].order(:start_time) #or return ALL appointments
      end
      status 200
      appts.all.to_json
    rescue Exception
      status 400
      'invalid date'.to_json
    end
  end

  get '/appointments/:id' do
    appt = Appt[params[:id].to_i]
    if appt
      status 302
        appt.values.to_json
    else
      status 404
      'no appointment found'.to_json
    end
  end

  post '/appointments' do
    data = filter_params
    appt = Appt.new(data)
    if appt.valid?
      appt.save
      status 200
      appt.values.to_json
    else
      status 400
      appt.errors.to_json
    end
  end

  put '/appointments/:id' do
    data = filter_params
    appt = Appt[params[:id].to_i]
    if appt
      begin
        appt.update(data)
        status 202
        appt.values.to_json
      rescue Exception
        status 400
        appt.errors.to_json
      end
    else
      status 404
      'no appointment found'.to_json
    end
  end

  delete '/appointments/:id'do
    appt = Appt[params[:id].to_i]
    if appt.nil?
      status 404
    else
      appt.delete
      status 202
    end
  end
end

def filter_params
  strong_params = ['first_name', 'last_name', 'start_time', 'end_time', 'comments']
  params.select { |k, v| strong_params.include? k }
end

def time_params?
  filter_params['start_time'] || filter_params['end_time']
end

def find_appointments
  if filter_params['start_time'] && filter_params['end_time']
    DB[:appts].where{|a| a.start_time >= filter_params['start_time'].to_s}. #Scan the the Table. For each appointment compare to NEW start time.
               where{|a| a.end_time <= filter_params['end_time'].to_s} #if new start_time is greater AND its end_time is less than or equal
  elsif filter_params['start_time']
    DB[:appts].where{|a| a.start_time >= filter_params['start_time'].to_s}
  else
    DB[:appts].where{|a| a.end_time <= filter_params['end_time'].to_s}
  end
end

def invalid_dates?(object, value)
  begin
    (object[:start_time] >= object[:end_time] ||
      value < Time.now)
  rescue Exception
    true
  end
end

def overlap_date?(object, attribute, time)
  begin
    if attribute == :start_time
      appts = Appt.where{|a| a.start_time <= time.to_s}.
                   where{|a| a.end_time > time.to_s}
    else
      appts = Appt.where{|a| a.end_time >= time.to_s}.
                   where{|a| a.start_time < time.to_s}
    end
    if object[:id]
      appts = appts.where{|a| a.id == object[:id].to_i}
    end
    appts.any?
  rescue Exception
    true
  end
end

def surround_date?(object)
  begin
    appts = DB[:appts].where{|a| a.start_time > object[:start_time].to_s}.
                       where{|a| a.start_time < object[:end_time].to_s}
    appts.any?
  rescue Exception
    true
  end
end