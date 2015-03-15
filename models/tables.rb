DB.create_table?  :users do
  primary_key :id 
  String      :username     , null: false   , text: false   , unique: true
  String      :password     , null: false   , text: false
  String      :email        , null: false   , text: false
  TrueClass   :show_email   , null: false
  Time        :created_at   , null: false
end

DB.create_table?  :indices do
  primary_key :id
  foreign_key :user_id
  String      :name         , null: false   , text: false
  TrueClass   :user_is_anon , null: false
  TrueClass   :hidden_index , null: false
  TrueClass   :show_pushed_at   , null: false
  TrueClass   :show_commited_at , null: false
  Time        :created_at   , null: false
end 

DB.create_table?  :files do
  primary_key :id
  Integer     :size         , null: false
  String      :sha2_512     , null: false   , text: false , fixed: true , size: 128
  Time        :created_at   , null: false
  unique      [:size, :sha2_512]
end

DB.create_table?  :revisions do
  primary_key :id
  foreign_key :index_id
  String      :rid          , null: false   , text: false , fixed: true , size: 128 , index: true
    # rid = sha2_512(commit_time)
  Time        :commited_at  , null: false
  Time        :pushed_at    , null: false
end

DB.create_table?  :objects_revisions do
  foreign_key :object_id
  foreign_key :revision_id
  primary_key [:object_id, :revision_id]
end

DB.create_table?  :objects do
  primary_key :id
  foreign_key :file_id
  foreign_key :index_id
  String      :oid          , null: false   , text: false , fixed: true , size: 128 , index: true
    # oid = sha2_512(index.username index.name file.size file.sha2_512 path)
  String      :name         , null: true    , text: true
  String      :path         , null: true    , text: true
    # JSON ['dir','dir','file']
  Time        :created_at   , null: true
    # note create_at is not "reliable"
    # it's a metadata added ad-hoc that doesn't fit into the
    # snapshot <key, value> model wix uses.
    # i.e.:
    # > touch file
    # > wix add file
    # > wix commit ; wix push
    # o1 = object of file
    # > rm file
    # > touch file
    # > wix add file
    # > wix commit ; wix push
    # o2 = object of file
    # o1.created_at == o2.created_at
end
