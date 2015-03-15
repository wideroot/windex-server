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
  set_primary_key [:object_id, :revision_id]
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
  def snapshot
    objects.select { |object| object.command != 1 }
  end
  def removed_objects
    objects.select { |object| object.command == 1 }
  end
  def added_objects
    objects.select { |object| object.command == 0 }
  end
  def untouched_objects
    objects.select { |object| object.command == -1 }
  end
private
  # TODO probably is better use sql instead assoc
  # such as Object.where('revision_id = :rid AND command != 1', rid: revision_id)
  one_to_many     :objects
end

class Object
  many_to_one     :file
end


end
