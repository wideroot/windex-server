helpers do
  def create_table header, rows
    table = "<table>"

    table += "<thead>"
    table += "<tr><th>" + header.join("</th><th>") + "</th></tr>"
    table += "</thead>"

    table += "<tbody>"
    rows.each do |row|
      table += "<tr><td>" + row.join("</td><td>") + "</td></tr>"
    end
    table += "</tbody>"

    table += "</table>"
    table
  end

  def create_reverse_table header, rows
    rows = [rows] unless rows.first.respond_to(:each)
    table = "<table>"

    table += "<tbody>"
    header.zip(rows) do |key, values|
      table += "<tr><th>#{key}</th><td>#{values.join("</td><td>")}</td></tr>"
    end
    table += "</tbody>"

    table += "</table>"
    table
  end
end
