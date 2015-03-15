require 'rubygems'
require 'bundler'

Bundler.require

require './windex_server_app'
run Sinatra::Application
