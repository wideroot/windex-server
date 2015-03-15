require 'sinatra'
require 'sinatra/r18n'
require_relative './db_connection.rb'

configure do
  set :environment, ENVIRONMENT
  R18n::I18n.default = 'en'
end

configure :development do
  set :server, %w[webrick]
  enable :raise_errors
  enable :show_exceptions
  enable :logging
  enable :dump_errors
  enable :static

  enable :reload_tempaltes
  require 'sinatra/reloader'
  enable :reloader
end

require_relative './server.rb'
