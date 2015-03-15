MAX_USER_TO   = 100
MAX_FILES_TO  = 1000




def authenticate!
  @auth ||= Rack::Auth::Basic::Request.new(request.env)
  if @auth.provided? and @auth.basic? and @auth.credentials
    name, password = @auth.credentials
    user = Wix::User.where(name: name, password: password).first
  end
  if user == nil
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, (te :not_authorized, {message: "Invalid username or password."})
  end
  user
end




post '/push/:name' do |name|
  user = authenticate!
  begin
    revisions = JSON.parse(params[:revisions])
  rescue => ex
    halt 400, (te: :invalid_push, {message: "Invalid revisions field'"})
  end

  pushed_at = Sequel.datetime_class.now

  index = Indices.first_or_create(user_id: user.id, name: index_name) do |index|
    # TODO improve parameters checking...
    index.user_is_anon    = params[:user_is_anon] == 'true'
    index.hidden          = params[:hidden_inted] == 'true'
    index.show_pushed_at  = params[:show_pushed_at] == 'true'
    index.hidden          = params[:show_commited_at] == 'true'
    index.created_at      = pushed_at
  end

  # TODO catch exceptions...
  added_revisions = false
  DB.transaction do
    revisions.each do |revision|
      # if user try to upload pushed commits, ignore
      revision = Revision.first_or_new(index_id: index.id, rid: revision['rid'])
      next if !revision.new? && !added_revisions
      added_revisions = true
      # TODO improve this logic...
      # TODO use a first_or_insert instead first_or_new...

      revision.commited_at = Time.new(revision['commited_at'])
      revision.pushed_at = pushed_at
      revision.save!

      revisions['objects'].each do |object|
        # get file object references, creating a new if needed
        # TODO use a first_or_insert instead first_or_new...
        file = Wix::File.first_or_create(
          size: object['size'],
          sha2_512: object['sha2_512'],
        )
        object_id = Wix::Object.insert(
          file_id: file.id,
          revision_id: revision.id,
          index_id: file.id,
          name: object['name'],
          path: object['path'],
          created_at: object['created_at'],
        )
      end
    end
  end
end




def get_user user_identifier
  halt 404 if user_identifier.empty?
  user = if user_identifier[0] =~ /[[:digit:]]/
    Wix::User.where(id: user_identifier).first
  else
    Wix::User.where(username: user_identifier).first
  end
  halt 404 unless user
end

def check_user_permissions_for_user user1, user2
  return if user1 == user2
  halt 401, (te :not_authorized, {message: "Not authorized to see #{user2.username} private information."})
end


get '/user/:user' do |user|
  user = get_user(user)
  te :user, {user: user}
end
get '/user/:user/public_indices' do |user|
  user = get_user(user)
  te :public_indices, {user: user}
end

get '/user/:user/private_indices' do |user|
  user_auth = authenticate!
  user = get_user(user)
  halt 404 unless user
  check_user_permissions_for_user!(user_auth, user)
  te :private_indices, {user: user}
end

get '/user/:user/show/:index' do |user, index|
  # TODO force check user
  request.path_info = "/index/#{index}"
end

get '/user/:user/commits/:index' do |user, index|
  # TODO force check user
  request.path_info = "/commits/#{index}"
end

get '/user/:user/show/:index/:revision' do |user, index, revision|
  # TODO force check user, index
  request.path_info = "/revision/#{revision}"
end

get '/user/:user/show/:index/:revision/:object' do |user, index, revision, object|
  # TODO force check user, index, revision
  request.path_info = "/object/#{object}"
end




get '/file/:size/sha2_512/:sha2_512' do |size, sha2_512|
  # TODO truncate sha2_512.truncate(128) ... ? do not dup then...
  files = Wix::File.where(size: size, sha2_512: sha2_512).all
  halt 404 if files.empty?
  te :file, {files: files}
end

get '/object/:object_id' do |object_id|
  object = Wix::Object[object_id]
  halt 404 unless object
  te :object, {object: object}
end

get '/commits/:index_id' do |index_id|
  index = Wix::Object[index_id]
  halt 404 unless index
  te :commits, {index: index}
end

get '/index/:index_id' do |index_id|
  index = Wix::Object[index_id]
  halt 404 unless index
  request.path_info = '/snapshot/#{index.head.id}'
end

get '/revision/:revision_id' do |revision_id|
  revision = Wix::Object[revision_id]
  halt 404 unless revision
  te :revision, {revision: revision}
end




get '/users' do
  request.path_info = '/users/0/100'
end
get '/users/:from/:to' do |from, to|
  from = from.to_i
  to = [to.to_i, MAX_USER_TO].max
end

get '/files' do
  request.path_info = '/files/0/100'
  from = from.to_i
  to = [to.to_i, MAX_FILES_TO].max
end
