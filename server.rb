require 'pp'  # XXX
require 'date'
require 'ostruct'




$source_files = []
$source_files += Dir["./models/tables.rb"]
$source_files += Dir["./models/models.rb"]
$source_files += Dir["./models/**/*.rb"]
$source_files += Dir["./helpers/**/*.rb"]
$source_files += Dir["./routes/**/*.rb"]
$source_files.each { |file| require_relative file }




def force_reload
  return if !settings.reloader
  `find . -name '*.rb'`.split("\n").each { |file| also_reload file }
  $source_files.each { |file| also_reload file }
end

configure :development do
  force_reload
end




def api_request?
  request.path_info.start_with? '/api/'
end

before do
  # TODO implement it
  $user = nil
  pass if request.path_info == '/sign_out' || api_request?
  puts session.inspect
  if session[:username]
    $user = Wix::User.first(username: session[:username])
  end
end

get '/' do
  te :index
end

not_found do
  [404, (te :not_found)]
end

after do
  pass if api_request?
  session[:username] = $user ? $user.username : nil
end
