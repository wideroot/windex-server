def authenticate! message = nil
  @auth ||= Rack::Auth::Basic::Request.new(request.env)
  if @auth.provided? and @auth.basic? and @auth.credentials
    name, password = @auth.credentials
    user = User.where(name: name, password: password).first
  end
  if user == nil
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, (te :not_authorized, {message: message})
  end
  user
end


post '/push/:name' do |name|
  user = authenticate!("Invalid user.")

  index_name = name.truncate(255)
  if index_name != name
    halt 406, (te: :invalid_push, {message: "Invalid name `#{name}'"})
  end

  begin
    revisions = JSON.parse(params[:revisions])
  rescue => ex
    halt 406, (te: :invalid_push, {message: "Invalid revisions field'"})
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
        file = Wix::File.first_or_create(
          size: object['size'],
          sha2_512: object['sha2_512'],
        )
        # look if the object was already pushed
        last_object = Wix::Object.where(
          index_id: index.id,
          oid: object['oid'],
        ).last
        if  last_object != nil &&
            # extra checks
            last_object.file_id == file.id &&
            last_object.name == object['name'] &&
            last_object.path == object['path']
          object_id = Wix::Object.insert(
            file_id: file.id,
            index_id: index.id,
            oid: object['oid'],
            name: object['name'],
            path: object['path'],
            created_at: object['created_at'],
          )
        end

        # add object to the revision
        DB[:objects_revisions].insert(revision_id: revision_id, object_id: object_id)
      end
    end
  end
end


post '/push' do
  user = authenticate!("Invalid user.")
  push = JSON.parse(params[:push])
  push[:index_name]
  push[:]
end


get '/file/size/:size/sha2_512/:sha2_512' do |size, sha2_512|
  # TODO improve type safeness...
  size = size.to_i
  # TODO truncate sha2_512.truncate(128) ... ? do not dup then...

  files = Wix::File.where(size: size, sha2_512: sha2_512).all
  if files.empty?
    halt 404, (te :file_not_found)
  else
    te :file, {files: files}
  end
end
