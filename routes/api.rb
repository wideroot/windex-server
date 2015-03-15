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
    commits = JSON.parse(params[:commits])
  rescue => ex
    halt 400, (te :invalid_push, {message: "Invalid commits field'"})
  end

  pushed_at = Sequel.datetime_class.now

  DB.transaction do
    # TODO refactor
    index = Indices.where(
      user_id:      user.id,
      name:         index_name,
      removed:      false,
      anon:         params['anon'].to_b,
      hidden:       params['hidden'].to_b,
      filename:     params['filename'].to_b,
      path:         params['path'].to_b,
      push_time:    params['push_time'].to_b,
      commit_time:  params['commit_time'].to_b,
      message:      params['messages'].to_b,
      file_time:    params['file_time'].to_b,
    ).last
    if index
      if index.id == Indices.select(:id).last
        index_id = index.id
        index.removed = true
        index.removed_at = pushed_at
      else
        index.updated_at = pushed_at
      end
      index.save
      index = nil
    end
    if index_id == nil
      index_id = Indices.select(:id).where(
        user_id:      user.id,
        name:         index_name,
        removed:      false,
        anon:         params['anon'].to_b,
        hidden:       params['hidden'].to_b,
        filename:     params['filename'].to_b,
        path:         params['path'].to_b,
        push_time:    params['push_time'].to_b,
        commit_time:  params['commit_time'].to_b,
        message:      params['messages'].to_b,
        file_time:    params['file_time'].to_b,
        created_at:   pushed_at,
        updated_at:   pushed_at,
        removed_at:   nil,
      ).last
    end

    # TODO catch exceptions...
    added_commits = false
    commits.each do |commit|
      # if user try to upload pushed commits, ignore
      commit = Wix::Commit.first_or_new(
        index_id: index_id,
        rid: commit['rid'],
      )
      next if !commit.new? && !added_commits
      added_commits = true
      # TODO improve this logic...
      # TODO use a first_or_insert instead first_or_new...

      commit.message = commit['message']
      commit.commited_at = Time.new(commit['commited_at'])
      commit.pushed_at = pushed_at
      commit.save!

      commits['objects'].each do |object|
        # get file object references, creating a new if needed
        # TODO use a first_or_insert instead first_or_new...
        file = Wix::File.first_or_create(
          size: object['size'],
          sha2_512: object['sha2_512'],
        )
        object_id = Wix::Object.insert(
          file_id: file.id,
          commit_id: commit.id,
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
  # TODO CALCULATE INDEX NAME... last...
  request.path_info = "/index/#{index}"
  pass
end

get '/user/:user/commits/:index' do |user, index|
  # TODO CALCULATE INDEX NAME...
  request.path_info = "/commits/#{index}"
  pass
end

get '/user/:user/show/:index/:commit' do |user, index, commit|
  # TODO check...
  request.path_info = "/commit/#{commit}"
  pass
end

get '/user/:user/show/:index/:commit/:object' do |user, index, commit, object|
  # TODO force check user, index, commit
  request.path_info = "/object/#{object}"
  pass
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
  request.path_info = "/snapshot/#{index.head_id}"
  pass
end

get '/snapshot/:commit_id' do |commit_id|
  commit = Wix::Object[commit_id]
  halt 404 unless commit
  te :snapshot, {commit: commit}
end

get '/commit/:commit_id' do |commit_id|
  commit = Wix::Object[commit_id]
  halt 404 unless commit
  te :commit, {commit: commit}
end




get '/users' do
  request.path_info = '/users/0/100'
  pass
end
get '/users/:from/:limit' do |from, limit|
  from = from.to_i
  limit = [limit.to_i, MAX_USER_TO].max
  users = Wix::User.limit(limit).offset(from)
  te :users, {users: users}
end

get '/files' do
  request.path_info = '/files/0/100'
  pass
end
get '/files/:from/:limit' do |from, limit|
  from = from.to_i
  limit = [limit.to_i, MAX_FILES_TO].max
  files = Wix::File.limit(limit).offset(from)
  te :files, {files: files}
end
