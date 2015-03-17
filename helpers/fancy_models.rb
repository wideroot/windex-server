def url_x s
  s  # TODO srsly...
end

module Wix

class User
  def link
    %Q{<a href="#{url_x ("/api/user/#{username}")}">@#{username}</a>}
  end
  def private_indices_link
    %Q{<a href="#{url_x ("/api/user/#{username}/private_indices")}">@#{username}</a>}
  end
  def link
    %Q{<a href="#{url_x ("/api/user/#{username}/public_indices")}">@#{username}</a>}
  end
end

class Index
end

class File
    #%Q{<a href="#{url_x ("/api/files/size/#{size}/sha2_512/#{sha2_512}")}">##{id}</a>}
  def link
    %Q{<a href="#{url_x ("/api/file/#{id}")}">##{id}</a>}
  end
end

class Commit
  def link
    %Q{<a href="#{url_x ("/api/commit/#{id}")}">r#{id}</a>}
  end

  def index_link
    %Q{<a href="#{url_x ("/api/index/#{index_id}")}">*#{index_id}</a>}
  end
end

class Object
  def link
    %Q{<a href="#{url_x ("/api/object/#{id}")}">o#{id}</a>}
  end

  def commit_link
    %Q{<a href="#{url_x ("/api/object/#{id}/commit")}">commit</a>}
  end

  def file_link
    %Q{<a href="#{url_x ("/api/file/#{id}")}">##{id}</a>}
  end
end


end

