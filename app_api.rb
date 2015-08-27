require 'sinatra/base'
require 'sinatra/sequel'
require 'json'

if ENV['RACK_ENV'] == 'test'
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

class Appt < Sequel::Model
  plugin :validation_helpers
  plugin :validation_class_methods
  set_primary_key [:id]
  def validate #validate new appointments and updates
    super
    validates_presence [:first_name, :last_name, :start_time, :end_time]
    validates_format /^[a-z ,.'-]+$/i, [:first_name, :last_name]
    validates_format /^$|^[a-zA-Z0-9 .!?"-]+$/, :comments
    validates_schema_types [:start_time, :end_time]
  end
  #checks each Start_time and End_time for overlapping conflicts and invalid datetime
  validates_each :start_time, :end_time do |object, attribute, value|
    object.errors.add(attribute, 'datetime overlap') if overlap_date?(object, attribute, value)
  end
  validates_each :start_time do |object, attribute, value|
    object.errors.add(attribute, 'old_start_date') if old_start_date?(value)
    object.errors.add(attribute, 'invalid datetime') if invalid_dates?(object)
    object.errors.add(attribute, 'datetime overlap') if surround_date?(object)
  end

end

class AppApi < Sinatra::Application
  # calls method to create postgres scope if any
  # if pg_code 'nil' then returns all
  get '/appointments' do
    # binding.pry
    begin
      if time_params?
        appts = find_appointments
      else
        appts = DB[:appts].order(:start_time)
      end
      status 200
      appts.all.to_json
    rescue Exception
      status 400
      'invalid date'.to_json
    end
  end

  #if appt is found them return json
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

  #calls method to filter unwanted params
  #runs validation Sequel method
  #returns errors if any
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

  # calls method to filter unwanted params
  # check if appointment exist
  # if any errors during update then update then it returns errors
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

  # if appointment does not exist then return errors
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
  filter_params['start_time'] || filter_params['end_time'] ? true : false
end

def find_appointments
  if filter_params['start_time'] && filter_params['end_time']
    appts = DB[:appts].where{|a| a.start_time >= filter_params['start_time'].to_s}
    appts.where{|a| a.end_time <= filter_params['end_time'].to_s}
  elsif filter_params['start_time']
    DB[:appts].where{|a| a.start_time >= filter_params['start_time'].to_s}
  else
    DB[:appts].where{|a| a.end_time <= filter_params['end_time'].to_s}
  end
end

def invalid_dates?(object)
  begin
    (object[:start_time] > object[:end_time] || #checks to see if end time is before start time
      object[:start_time] == object[:end_time]) #checks for valid appointment time
  rescue Exception
    true
  end
end

def old_start_date?(value)
  begin
    value < Time.now #checks for future date
  rescue Exception
    true
  end
end

def overlap_date?(object, attribute, time)
  begin
    if attribute == :start_time
      appts = Appt.where{|a| a.start_time <= time.to_s}
      appts = appts.where{|a| a.end_time > time.to_s}
    else
      appts = Appt.where{|a| a.end_time >= time.to_s}
      appts = appts.where{|a| a.start_time < time.to_s}
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
    appts = DB[:appts].where{|a| a.start_time > object[:start_time].to_s}
    appts = appts.where{|a| a.start_time < object[:end_time].to_s}
    appts.any?
  rescue Exception
    true
  end
end
