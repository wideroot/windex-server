require_relative "./constants.rb"
require 'logger'
require 'json'


require 'sequel'
Sequel::Model.plugin :timestamps, update_on_create: true


# default SequelModel 
class Sequel::Model
  unrestrict_primary_key
end

module Sequel
  class Model
    module ClassMethods
  def first_or_create(cond = nil, &block)
    if cond
      first(cond) || create(cond, &block)
    else
      first || create(&block)
    end
  end

  def first_or_new(cond = nil, &block)
    if cond
      first(cond) || new(cond, &block)
    else
      first || new(&block)
    end
  end

    end
  end
end


# connect
# sql to create db
# DROP DATABASE seg; CREATE DATABASE seg DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
DB = Sequel.connect adapter: DBC_ADAPTER, database: DBC_DATABASE, user: DBC_USER, password: DBC_PASSWORD, host: DBC_HOST, port: DBC_PORT
if defined?(ENVIRONMENT) && ENVIRONMENT == :development
  DB_LOG_FILE   = $stderr     unless defined? DB_LOG_FILE
  DB_LOG_LEVEL  = :debug      unless defined? DB_LOG_LEVEL
  DB.logger = Logger.new DB_LOG_FILE
  DB.sql_log_level = DB_LOG_LEVEL
end
