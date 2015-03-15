def authenticate! message = nil
  @auth ||= Rack::Auth::Basic::Request.new(request.env)
  if @auth.provided? and @auth.basic? and @auth.credentials
    name, password = @auth.credentials
    user = Wix::User.where(name: name, password: password).first
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
