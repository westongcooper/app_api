require 'sinatra/base'
require 'sinatra/sequel'
require 'pry'
require 'json'


if ENV['RACK_ENV'] == 'test' #switch database access for testing environment
  DB = Sequel.connect(:adapter=>'postgres',
                      :host=>'localhost',
                      :database=>'app_api_test',
                      :user=>'westoncooper')
else
  DB = Sequel.connect(:adapter=>'postgres',
                      :host=>'localhost',
                      :database=>'app_api_development',
                      :user=>'westoncooper',
                      :password=>ENV['PG_password'])
end

class Appt < Sequel::Model
  plugin :validation_helpers
  plugin :validation_class_methods
  set_primary_key [:id]
  def validate #validate new appointments and updates
    super
    validates_presence [:first_name, :last_name, :start_time, :end_time]
    validates_format /^[a-zA-Z]+$/, [:first_name, :last_name]
    validates_format /^$|^[a-zA-Z0-9 .!?"-]+$/, :comments
    validates_schema_types [:start_time,:end_time]
  end
  #checks each Start_time and End_time for conflicts
  validates_each :start_time, :end_time do |object, attribute, value|
    object.errors.add(attribute, "invalid datetime") unless check_date(object, attribute, value)
  end
end

def check_date(object, attribute, value)
  begin
    value < Time.now ? (return false) : true #checks for future date
    object[:start_time] > object[:end_time] ? (return false) : true #checks to see if end time is before start time
    if attribute == :start_time #creates SQL command to search for conflicting appointments
      pg_code = "(start_time >= '#{object[:start_time]}') AND (start_time < '#{object[:end_time]}')"
    else
      pg_code = "(end_time < '#{object[:end_time]}') AND (end_time > '#{object[:start_time]}')"
    end
    if object[:id] #adds exception if updating current appointment
      pg_code += " AND (id != #{object[:id]})"
    end
    old_appts = Appt.where{pg_code} #runs postgres scope
    old_appts.empty? #if empty then validation passes
  rescue Exception
    false #if any errors with start and end times then it fails validation
  end
end

class AppApi < Sinatra::Application

  get '/appointments' do
    begin
      pg_code = create_sql #calls method to create postgres scope if any
      status 200
      DB[:appts].where{pg_code}.order(:start_time).all.to_json #if pg_code 'nil' then returns all
    rescue Exception
      status 400
      'invalid date'.to_json
    end
  end

  get '/appointments/:id' do
    appt = Appt[params[:id]]
    if appt #if appt is found them return json
      status 302
      appt.values.to_json
    else
      status 404
      'no appointment found'.to_json
    end
  end

  post '/appointments' do
    data = filter_params #calls method to filter unwanted params
    appt = Appt.new(data)
    if appt.valid? #runs validation Sequel method
      appt.save
      status 200
      appt.values.to_json
    else #returns errors if any
      status 400
      appt.errors.to_json
    end
  end

  put '/appointments/:id' do
    data = filter_params #calls method to filter unwanted params
    appt = Appt[params[:id]]
    if appt #check for appointment
      begin #if any errors during update then update then return errors
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
    appt = Appt[params[:id]]
    if appt.nil? #if appointment does not exist then return error
      status 404
    else
      appt.delete
      status 202
    end
  end


  def filter_params  #filter out unwanted params
    strong_params = ['first_name', 'last_name', 'start_time', 'end_time', 'comments']
    params.select { |k, v| strong_params.include? k }
  end
  def create_sql  #create SQL code for Postgres query
    if filter_params['start_time']
      start_time = "(start_time >= '#{filter_params['start_time']}')"
    end
    if filter_params['end_time']
      end_time = "(end_time <= '#{filter_params['end_time']}')"
    end
    if filter_params['start_time'] && filter_params['end_time']
      pg_code = "#{start_time} AND #{end_time}"
    elsif filter_params['start_time']
      pg_code = start_time
    else
      pg_code = end_time
    end
    pg_code
  end
end