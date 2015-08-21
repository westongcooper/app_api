ENV['RACK_ENV'] = 'test'
require 'sinatra'
require 'rspec'
require 'rack/test'
require 'sinatra/sequel'
require 'time_params.rb'



DB_test = Sequel.connect('postgres://westoncooper@localhost/app_api_test')
class Appt < Sequel::Model
  set_primary_key [:id]
end

module RSpecMixin
  include Rack::Test::Methods
  def app
    AppApi
  end
end

RSpec.configure do |config|
  config.include RSpecMixin
  config.include Time_params
  config.after(:suite) {DB[:appts].delete }
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
end