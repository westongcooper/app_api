ENV['RACK_ENV'] = 'test'
require 'sinatra'
require 'rspec'
require 'rack/test'

# DB = Sequel.connect('postgres://westoncooper@localhost/app_api_test')
module RSpecMixin
  include Rack::Test::Methods
  def app
    AppApi
  end
end

RSpec.configure do |config|
  config.include RSpecMixin

  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
end