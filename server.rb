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




get '/' do
  te :index
end

not_found do
  # TODO fins a nice way to do
  # te :not_found if request.body == '<h1>Not Found</h1>'
end
