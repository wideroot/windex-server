# utility to drop the tables
require_relative './db_connection.rb'
DB.drop_table? :users
DB.drop_table? :files
DB.drop_table? :indices
DB.drop_table? :commits
DB.drop_table? :objects
