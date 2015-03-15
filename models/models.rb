module Wix


class User < Sequel::Model
  set_primary_key :id
end

class Index < Sequel::Model
  set_primary_key :id
end

class File < Sequel::Model
  set_primary_key :id
end

class Revision < Sequel::Model
  set_primary_key :id
end

class ObjectRevision < Sequel::Model
  set_primary_key [:object_id, :revision_id]
end

class Object < Sequel::Model
  set_primary_key :id
  plugin :serialization, :json
  serialize_attributes  :json , :path
end


# associations
class User
  one_to_many     :indices
end

class Index
  many_to_one     :user
  one_to_many     :revisions
  def head
    revisions.max { |revision| revision.id }
  end
end

class File
  one_to_many     :objects
end

class Revision
  many_to_one     :index
end

class Object
  many_to_one     :file
  many_to_one     :index
end


end
