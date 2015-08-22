require 'sinatra/base'
require 'sinatra/sequel'
require 'json'
require './Appointments_model'
require './helpers/sql'

class AppApi < Sinatra::Application
  # calls method to create postgres scope if any
  # if pg_code 'nil' then returns all
  get '/appointments' do
    begin
      pg_code = create_sql_helper
      status 200
      DB[:appts].where{pg_code}.order(:start_time).all.to_json
    rescue Exception
      status 400
      'invalid date'.to_json
    end
  end

  #if appt is found them return json
  get '/appointments/:id' do
    appt = Appt[params[:id]]
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
    appt = Appt[params[:id]]
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
    appt = Appt[params[:id]]
    if appt.nil?
      status 404
    else
      appt.delete
      status 202
    end
  end


  #filter out unwanted params
  def filter_params
    strong_params = ['first_name', 'last_name', 'start_time', 'end_time', 'comments']
    params.select { |k, v| strong_params.include? k }
  end
end
