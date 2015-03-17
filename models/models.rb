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

class Commit < Sequel::Model
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
  one_to_many     :commits
  def head_id
    Wix::Commit.select(:id).where(index_id: id).last
  end
  def head
    # TODO do it in sql if commits was not load...?
    # TODO is commits.last enough...?
    # commits.max { |commit| commit.id }
    Wix::Commit.where(index_id: id).last
  end
end

class File
  one_to_many     :objects
end

class Commit
  many_to_one     :index
  many_to_one     :objects
end

class Object
  many_to_one     :file
  many_to_one     :commit
end


end
