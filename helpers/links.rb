helpers do

  def list_files name, from = 0, limit = 1000
    to = from + limit
    if from < 0
      from = 0
      limit = to - from
    end
    return "" if limit <= 0
    %Q{<a href="#{url ("/api/list/files/#{from}/#{limit}")}">#{name}</a>}
  end

  def next_previous_list_files from, limit
    "<p>#{list_files("previous", from - limit, limit)} #{list_files("next", from + limit, limit)}</p>"
  end

end
