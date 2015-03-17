helpers do

  def te template, resp = {}
    erb template, locals: {resp: OpenStruct.new(resp)}  # TODO use a recursive open struct?
  end

end


class String
  def truncate truncate_at
    length <= truncate_at ? dup : self[0, truncate_at]
  end
end
