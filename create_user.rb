require_relative './db_connection.rb'
require_relative './models/tables.rb'
require_relative './models/models.rb'
Wix::User.first_or_create(username: 'test') do |u|
  u.password = 'test'
  u.email = 'test'
  u.show_email = false
  u.created_at = Time.now
end
