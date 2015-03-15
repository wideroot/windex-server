DB.create_table?  :users do
  primary_key :id 
  String      :username     , null: false   , text: false
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
  Time        :created_at   , null: false
end 

DB.create_table?  :files do
  primary_key :id
  Integer     :size         , null: false
  String      :sha2_512     , null: false   , text: false , fixed: true , size: 128
  Time        :created_at   , null: false
end

DB.create_table?  :revisions do
  primary_key :id
  foreign_key :index_id
  Time        :commited_at  , null: false
  Time        :pushed_at    , null: false
  Integer     :config       , null: false
    # 0   show push_time
    # 1   show revision_time
end

DB.create_table?  :objects do
  String      :object_id    , null: false   , text: false , fixed: true , size: 128
  foreign_key :revision_id
  primary_key [:object_id, :revision_id]
  Integer     :command      , null: false
    # 0   add
    # 1   rm
    # -1  untouched/heartbeat
  foreign_key :file_id
  String      :name         , null: true    , text: true
  String      :path         , null: true    , text: true
    # JSON ['dir','dir','file']
  Time        :created_at   , null: true
end
