def save_session
  session[:username] = $user.username if $user
end

before do
  # TODO implement it
  $user = nil
  pass if request.path_info == '/sign_out'
  if session[:username]
    $user = Wix::User.first(username: session[:username])
  end
end

after do
  # XXX pass if api_request?
  save_session
end

get '/sign_out' do
  $user = nil
  session[:username] = nil
  redirect to '/', 307
end




get '/sign_in' do
  te :sign_in
end

post '/sign_in' do
  $user = Wix::User.first(username: params[:username], password: params[:password])
  save_session
  if $user
    redirect to '/', 307
  else
    resp = {error_message: "Invalid name or password"}
  end
  status 400
  te :sign_in, resp
end



get '/sign_up' do
  te :sign_up
end

def valid_field string
  string.length <= 255 && string =~ /^[A-Za-z][A-Za-z0-9_-]*/
end
def valid_mail string
  string.length <= 255
end

post '/sign_up' do
  # check
  secret = params[:secret]
  username = params[:username]
  email = params[:email]
  password = params[:password]
  resp = nil
  if !valid_field(username)
    resp = {error_message: "Invalid username"}
  elsif !valid_field(password)
    resp = {error_message: "Invalid password"}
  elsif !valid_mail(email)
    resp = {error_message: "Invalid mail"}
  elsif secret != 'wix'
    resp = {error_message: "Invalid secret"}
  else
    user = Wix::User.first_or_new(username: username)
    if user.new?
      user.password = password
      user.email = email
      user.show_email = true
      user.created_at = Sequel.datetime_class.now
      user.save
      $user = user
      redirect to '/', 307
    else
      resp = {error_message: "#{username} already exists"}
    end
  end
  status 400
  te :sign_up, resp
end
