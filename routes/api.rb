def authenticate!
  @auth ||= Rack::Auth::Basic::Request.new(request.env)
  if @auth.provided? and @auth.basic? and @auth.credentials
    username, password = @auth.credentials
    user = Wix::User.where(username: username, password: password).first
  end
  if user == nil
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, (te :not_authorized, {message: "Invalid username or password."})
  end
  user
end




# TODO post '/close_index/:index_name' do |index_name|
# end

post '/api/push/:index_name' do |index_name|
  user = authenticate!
  begin
    commits = JSON.parse(params[:push_file])
  rescue => ex
    pp ex
    halt 400, (te :invalid_push, {message: "Invalid commits field"})
  end
  begin
    push_commits(user, index_name, commits)
  rescue => ex
    pp ex
    halt 400, (te :invalid_push, {message: "Transaction failed: #{ex}"})
  end
  200
end

def push_commits user, index_name, commits
  pp commits
  # whether we've added some commit in this push
  pushed_at = Time.now.utc
  if commits.empty?
    raise "Malformed push_file: commits is empty"
  end
  if commits.first['index_config'] == nil
    raise "Malformed push_file: index_config not found in the first commit"
  end
  DB.transaction do
    # retrieve the last index (index config)
    last_index = Wix::Index.where(
        user_id:      user.id,
        name:         index_name,
        removed:      false,
      )
      .order_by(Sequel.desc(:id))
      .first
    added_commits = false

    commits.each do |commit|
      # use the previous index if this commit doesn't have one
      # note the first commit must have an index config
      ic = commit['index_config']
      index = last_index

      # create a new index if needed
      if index && ic
        if ic['force_new']
          # if there was an existent index and this commits is intended
          # to be the first one throw an error
          raise "Index already exists"
        end
        # check if we need to upload the index
        if index.anon != ic['anon'] ||
           index.hidden != ic['hidden'] ||
           index.filename != ic['filename'] ||
           index.path != ic['path'] ||
           index.push_time != ic['push_time'] ||
           index.commit_time != ic['commit_time'] ||
           index.message !=  ic['message'] ||
           index.file_time != ic['file_time']
          if ic['force_no_update']
            # if force_no_update and but ic doesn't match index raise an error
            raise "Index must be updateds"
          end
          index.removed = true
          index.removed_at = pushed_at
          index.save
          index = nil
        else
          index.updated_at = pushed_at
        end
      end
      # create a new index (config) if needed
      if !index
        index = Wix::Index.create(
          user_id:      user.id,
          name:         index_name,
          from_index_id:last_index ? last_index.id : nil,
          removed:      false,
          anon:         ic['anon'],
          hidden:       ic['hidden'],
          filename:     ic['filename'],
          path:         ic['path'],
          push_time:    ic['push_time'],
          commit_time:  ic['commit_time'],
          message:      ic['message'],
          file_time:    ic['file_time'],
          created_at:   pushed_at,
          updated_at:   pushed_at,
          removed_at:   nil,
        )
      end
      last_index = index
      warn "created new index #{index.id}"

      # if user try to upload pushed commits, ignore
      # otherwise create a new commit
      c = Wix::Commit.first_or_new(
        index_id: index.id,
        rid: commit['rid'],
      )
      next if !c.new? && !added_commits
      added_commits = true

      # and save commit object
      c.message = commit['message']
      c.commited_at = utc_time_at(commit['commited_at'])
      c.pushed_at = pushed_at
      c.save

      commit['objects'].each do |object|
        # get file object references, creating a new if needed
        file = Wix::File.first_or_create(
          size: object['size'],
          sha2_512: object['sha2_512'],
        )
        object_id = Wix::Object.insert(
          file_id: file.id,
          commit_id: c.id,
          name: object['name'],
          path: object['path'],
          created_at: utc_time_at(object['created_at']),
          removed: object['removed'],
        )
      end
    end
    last_index.save_changes  # updated_at can change
  end
end

def utc_time_at seconds
  return nil if seconds.class != Integer
  begin
    return DateTime.strptime(seconds.to_s, "%s")
  rescue
    return nil
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


get '/api/user/:user' do |user|
  user = get_user(user)
  te :user, {user: user}
end
get '/api/user/:user/public_indices' do |user|
  user = get_user(user)
  te :public_indices, {user: user}
end

get '/api/user/:user/private_indices' do |user|
  user_auth = authenticate!
  user = get_user(user)
  halt 404 unless user
  check_user_permissions_for_user!(user_auth, user)
  te :private_indices, {user: user}
end



get '/api/file/:size/sha2_512/:sha2_512' do |size, sha2_512|
  # TODO truncate sha2_512.truncate(128) ... ? do not dup then...
  files = Wix::File.where(size: size, sha2_512: sha2_512).all
  halt 404 if files.empty?
  te :file, {files: files}
end

get '/api/object/:object_id' do |object_id|
  object = Wix::Object[object_id]
  halt 404 unless object
  te :object, {object: object}
end

get '/api/commits/:index_id' do |index_id|
  index = Wix::Object[index_id]
  halt 404 unless index
  te :commits, {index: index}
end

get '/api/index/:index_id' do |index_id|
  index = Wix::Object[index_id]
  halt 404 unless index
  pass
end

get '/api/snapshot/:commit_id' do |commit_id|
  commit = Wix::Object[commit_id]
  halt 404 unless commit
  te :snapshot, {commit: commit}
end

get '/api/commit/:commit_id' do |commit_id|
  commit = Wix::Object[commit_id]
  halt 404 unless commit
  te :commit, {commit: commit}
end




get '/api/list/files' do
  request.path_info = '/files/0/100'
  pass
end
get '/api/list/files/:from/:limit' do |from, limit|
  max_files_to = 1000  # TODO
  from = from.to_i
  limit = [limit.to_i, max_files_to].max
  files = Wix::File.limit(limit).offset(from)
  te :files, {files: files}
end
