$source_files = []
$source_files += Dir["./models/tables.rb"]
$source_files += Dir["./models/models.rb"]
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
  'Hi!'
end
