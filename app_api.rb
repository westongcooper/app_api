require 'sinatra/base'
require 'pry'

class AppApi < Sinatra::Application
  get '/' do
    'Hello API'
  end
end