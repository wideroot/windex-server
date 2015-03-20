# TODO 
# ids shouldn't be autoincrements, but randome values, since it'd be a
# security issue
# (otherwise set hidden  to true or push_times to false would be completely useless)
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
  foreign_key :root_index_id, :indices, key: :id, null: true  # TODO
  foreign_key :from_index_id, :indices, key: :id, null: true
  TrueClass   :removed      , null: false
  foreign_key :user_id
  String      :name         , null: false   , text: false
  String      :display_name , null: false   , text: false
  TrueClass   :anon         , null: false
  TrueClass   :hidden       , null: false
  TrueClass   :filename     , null: false
  TrueClass   :resource_identifier   , null: false
  TrueClass   :push_time    , null: false
  TrueClass   :commit_time  , null: false
  TrueClass   :message      , null: false
  TrueClass   :file_time    , null: false
  Time        :created_at   , null: false
  Time        :updated_at   , null: false
  Time        :removed_at   , null: true
end 

DB.create_table?  :files do
  primary_key :id
  Integer     :size         , null: false
  String      :sha2_512     , null: false   , text: false , fixed: true , size: 128
  unique      [:size, :sha2_512]
end

DB.create_table?  :commits do
  primary_key :id
  foreign_key :index_id     , null: false
  foreign_key :root_index_id, null: false   # index_id.root_index_id == root_index_id
  String      :rid          , null: false   , text: false , fixed: true , size: 128 , index: true
    # rid = sha2_512(commit_time)
  String      :message      , null: true    , text: true
  Time        :commited_at  , null: true
  Time        :pushed_at    , null: false
end

DB.create_table?  :objects do
  primary_key :id
  foreign_key :commit_id
  foreign_key :file_id
  String      :filename             , null: true    , text: true
  String      :resource_identifier  , null: true    , text: true
  Time        :created_at           , null: true    # (mtime)
  TrueClass   :removed              , null: false   # TODO probably instead of calling it removed, it'd be better to call it owned
end
