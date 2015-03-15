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
  TrueClass   :anon         , null: false
  TrueClass   :hidden       , null: false
  TrueClass   :filename     , null: false
  TrueClass   :path         , null: false
  TrueClass   :push_time    , null: false
  TrueClass   :commit_time  , null: false
  TrueClass   :message      , null: false
  TrueClass   :file_time    , null: false
  Time        :created_at   , null: false
end 

DB.create_table?  :files do
  primary_key :id
  Integer     :size         , null: false
  String      :sha2_512     , null: false   , text: false , fixed: true , size: 128
  Time        :created_at   , null: false
  unique      [:size, :sha2_512]
end

DB.create_table?  :commits do
  primary_key :id
  foreign_key :index_id
  String      :rid          , null: false   , text: false , fixed: true , size: 128 , index: true
    # rid = sha2_512(commit_time)
  String      :message      , null: true    , text: true
  Time        :commited_at  , null: false
  Time        :pushed_at    , null: false
end

DB.create_table?  :objects do
  primary_key :id
  foreign_key :commit_id
  foreign_key :file_id
  String      :name         , null: true    , text: true
  String      :path         , null: true    , text: true
    # JSON ['dir','dir','file']
  Time        :created_at   , null: true
end
