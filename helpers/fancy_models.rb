# TODO nulls should be explicity show

def url_x s
  s  # TODO forward to sinatra url...
end

module Wix

class User
  def link
    %Q{<a href="#{url_x ("/api/user/#{username}")}">@#{username}</a>}
  end
  def root_indices_link
    %Q{<a href="#{url_x ("/api/user/#{username}/root_indices")}">root indices</a>}
  end
  def all_indices_link
    %Q{<a href="#{url_x ("/api/user/#{username}/all_indices")}">all indices</a>}
  end
  def public_indices_link
    %Q{<a href="#{url_x ("/api/user/#{username}/public_indices")}">public indices</a>}
  end
end

class Index
  def link
    %Q{<a href="#{url_x ("/api/index/#{id}")}">*#{id}</a>}
  end
  def next_link
    next_index_id = Index.select(:id).where(from_index_id: id).first
    return nil if next_index_id == nil
    %Q{<a href="#{url_x ("/api/index/#{next_index_id}")}">*#{next_index_id}</a>}
  end
  def from_link
    return nil if from_index_id == nil
    %Q{<a href="#{url_x ("/api/index/#{from_index_id}")}">*#{from_index_id}</a>}
  end
  def root_link
    %Q{<a href="#{url_x ("/api/root_index/#{root_index_id}")}">*#{root_index_id}</a>}
  end
end

class File
    #%Q{<a href="#{url_x ("/api/files/size/#{size}/sha2_512/#{sha2_512}")}">##{id}</a>}
  def link
    %Q{<a href="#{url_x ("/api/file/#{id}")}">##{id}</a>}
  end
  def short_sha2_512
    sha2_512[0..16] + "..."
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

