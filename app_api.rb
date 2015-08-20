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
    validates_format /^$|^[a-zA-Z0-9 .!?"-]+$/, :comments
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
      pg_code = "(start_time >= '#{object[:start_time]}') AND (start_time < '#{object[:end_time]}')"
    else
      pg_code = "(end_time < '#{object[:end_time]}') AND (end_time > '#{object[:start_time]}')"
    end
    if object[:id]
      pg_code += " AND (id != #{object[:id]})"
    end
    old_appts = Appt.where{pg_code}
    old_appts.empty?
  rescue Exception
    false
  end
end

class AppApi < Sinatra::Application

  get '/appointments' do
    DB[:appts].all.to_json
  end

  get '/appointments/:id' do
    appt = Appt[params[:id]]
    if appt
      status 200
      appt.values.to_json
    else
      status 404
    end
  end

  post '/appointments' do
    data = filter_params
    appt = Appt.new(data)
    if appt.valid?
      appt.save
      status 201
      appt.values.to_json
    else
      status 400
      appt.errors.to_json
    end
  end

  put '/appointments/:id' do
    data = filter_params
    appt = Appt[params[:id]]
    begin
      appt.update(data)
      status 202
      appt.values.to_json
    rescue Exception
      status 400
      appt.errors.to_json
    end
  end

  delete '/appointments/:id'do
    appt = Appt[:id]
    appt.nil? ? (return status 404) : appt.delete
    status 202
  end

  def filter_params
    strong_params = ['first_name', 'last_name', 'start_time', 'end_time', 'comments']
    params.select { |k, v| strong_params.include? k }
  end

end