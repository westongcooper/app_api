ENV['RACK_ENV'] = 'test'
require 'sinatra'
require 'rspec'
require 'rack/test'
require 'sinatra/sequel'
require 'time_params.rb'
require 'factory_girl'
require 'faker'

FactoryGirl.definition_file_paths = %w{./factories ./test/factories ./spec/factories}
FactoryGirl.find_definitions

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
  config.after(:each) {DB[:appts].delete }
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
  config.include FactoryGirl::Syntax::Methods
end