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
    # TODO do it in sql if revisions was not load...?
    # TODO is revision.last enough...?
    revisions.max { |revision| revision.id }
  end
end

class File
  one_to_many     :objects
end

class Revision
  many_to_one     :index
  many_to_one     :objects
end

class Object
  many_to_one     :file
  many_to_one     :revision
end


end
