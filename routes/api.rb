def authenticate!
  user = try_authenticate
  return user if user
  headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
  halt 401, (te :not_authorized, {message: "Invalid username or password."})
end
def try_authenticate
  return @user if @user
  @auth ||= Rack::Auth::Basic::Request.new(request.env)
  if @auth.provided? and @auth.basic? and @auth.credentials
    username, password = @auth.credentials
    user = Wix::User.where(username: username, password: password).first
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
          root_index_id:last_index ? last_index.root_index_id : nil,
          from_index_id:last_index ? last_index.id : nil,
          removed:      false,
          user_id:      user.id,
          name:         index_name,
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
        if index.root_index_id == nil
          index.root_index_id = index.id
          # we do not need to save, because we are going to save the changes
          # in last_index.save_changes ...
        end
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
      c.root_index_id = index.root_index_id
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
          path: object['path'].to_json,
          created_at: utc_time_at(object['created_at']),
          removed: object['removed'],
        )
      end
    end
    last_index.save_changes  # updated_at can change
  end
end

def utc_time_at seconds
  return nil unless seconds.is_a?(Integer) && seconds > 0
  begin
    return DateTime.strptime(seconds.to_s, "%s")
  rescue
    return nil
  end
end


def get_user user_identifier
  halt 404 if user_identifier.empty?
  #user = if user_identifier[0] =~ /[[:digit:]]/
  #  Wix::User.where(id: user_identifier).first
  #else
  #  Wix::User.where(username: user_identifier).first
  #end
  user = Wix::User.where(username: user_identifier).first
  halt 404 unless user
  user
end

def permissions? user_auth, user
  puts "#{user_auth.inspect} vs #{user.inspect}"
  user_id = user.is_a?(Integer) ? user : user.id
  return user_auth && user_auth.id == user_id
end

def permissions! user_auth, user
  return if permissions?(user_auth, user)
  halt 401, (te :not_authorized, {message: "Not authorized to see private information of other user."})
end




get '/api/user/:user' do |user|
  user = get_user(user)
  user.email = nil unless user.show_email  # XXX
  te :user, {user: user, show_all: @user && @user.id == user.id}
end
get '/api/user/:user/public_indices' do |user|
  user = get_user(user)
  indices = Wix::Index
    .select(:id, :name, :removed)
    .where(user_id: user.id, anon: false, hidden: false)
    .all
  te :user_public_indices, {user: user, indices: indices}
end

get '/api/user/:user/all_indices' do |user|
  user_auth = authenticate!
  user = get_user(user)
  permissions!(user_auth, user)
  indices = Wix::Index
    .select(:id, :name, :removed, :created_at, :removed_at, :updated_at, :from_index_id, :root_index_id)
    .where(user_id: user.id)
    .order_by(Sequel.desc(:id))
    .all
  te :user_all_indices, {user: user, indices: indices}
end

get '/api/user/:user/root_indices' do |user|
  user_auth = authenticate!
  user = get_user(user)
  permissions!(user_auth, user)
  indices = Wix::Index
    .select(:id, :name, :removed, :created_at, :removed_at, :updated_at, :root_index_id)
    .where(user_id: user.id, root_index_id: :id)
    .order_by(Sequel.asc(:id))
    .all
  te :user_root_indices, {user: user, indices: indices}
end



# TODO filter here fields that shouldn't be exposed...
get '/api/files/size/:size/sha2_512/:sha2_512' do |size, sha2_512|
  # TODO truncate sha2_512.truncate(128) ... ? do not dup then...
  files = Wix::File
    .where(size: size, sha2_512: sha2_512)
    .order_by(Sequel.asc(:id))
    .all
  halt 404 if files.empty?
  te :files, {files: files}
end
get '/api/file/:id' do |id|
  file = Wix::File[id]
  halt 404 unless file
  objects = Wix::Object
    .order_by(Sequel.desc(:id))
    .all
  te :file, {file: file, objects: objects}
end

get '/api/object/:object_id' do |object_id|
  object = Wix::Object[object_id]
  halt 404 unless object
  te :object, {object: object}
end

get '/api/object/:object_id/commit' do |object_id|
  object = Wix::Object
    .select(:objects__id, :commit_id, :hidden)
    .where(objects__id: object_id)
    .left_outer_join(:commits, id: :commit_id)
    .left_outer_join(:indices, id: :index_id)
    .first
  halt 404 unless object
  hidden = object.commit.index.hidden
  rt = hidden ? "/api/hidden/#{object.id}" : "/api/commit/#{object.commit_id}"
  redirect to rt
end

get '/api/hidden/:object_id' do |object_id|
  object = Wix::Object[object_id]
  halt 404 unless object
  te :commit, {commit: nil, objects: [object]}
end

get '/api/commit/:commit_id' do |commit_id|
  user_auth = try_authenticate
  commit = Wix::Commit
    .select_all(:commits)
    .select_append(:hidden, :push_time, :user_id)
    .where(commits__id: commit_id)
    .left_outer_join(:indices, id: :index_id)
    .first
  puts commit.index.hidden
  halt 404 unless commit
  halt 401 unless permissions?(user_auth, commit.index.user_id) || !commit.index.hidden
  objects = Wix::Object.where(commit_id: commit.id).all
  commit.pushed_at = nil unless commit.index.push_time
  te :commit, {commit: commit, objects: objects}
end

get '/api/index/:index_id' do |index_id|
  user_auth = try_authenticate
  index = Wix::Index[index_id]
  halt 404 unless index
  halt 401 unless permissions?(user_auth, index.user_id) || !index.hidden
  user = Wix::User.select(:username).where(id: index.user_id).first
  commits = Wix::Commit
  if permissions?(user_auth, index.user_id)
    commits = commits.select(:id)
    commits = commits.select_append(:message)       if index.message
    commits = commits.select_append(:commited_at)   if index.commit_time
    commits = commits.select_append(:pushed_at)     if index.push_time
  end
  commits = commits
    .where(index_id: index.id)
    .order_by(Sequel.desc(:id))
    .all
  user = nil if index.anon && !permissions?(user_auth, index.user_id)
  te :index, {index: index, user: user, commits: commits}
end

get '/api/root_index/:index_id' do |index_id|
  user_auth = try_authenticate
  index = Wix::Index[index_id]
  halt 404 unless index
  halt 404 unless index.root_index_id == index.id
  permissions!(user_auth, index.user_id)
  indices = Wix::Index
    .where(root_index_id: index.id)
    .order_by(Sequel.desc(:id))
    .all
  te :root_index, {indices: indices, user: user_auth}
end

=begin
log/object
diff/commit/commit
stats/file
TODO id mechanism is not safe...
=end





get '/api/list/files' do
  request.path_info = '/api/list/files/0/1000'
  pass
end
get '/api/list/files/:from/:limit' do |from, limit|
  max_files_to = 1000  # TODO
  from = from.to_i
  limit = [limit.to_i, max_files_to].max
  not_found if from < 0 || limit < 0
  files = Wix::File.limit(limit).order_by(Sequel.asc(:id)).offset(from).all
  te :list_files, {files: files, from: from, limit: limit}
end
