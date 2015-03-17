helpers do
  def create_table header, rows
    rows = [rows] if !rows.empty? && ! rows.first.respond_to?(:join)

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

  def create_rtable header, rows
    rows = [rows] if !rows.empty? && ! rows.first.respond_to?(:join)

    rows = rows.unshift(header).transpose

    table = "<table>"

    table += "<tbody>"
    rows.each do |row|
      header = row.shift
      table += "<tr><th>#{header}</th><td>"
      table += row.join("</td><td>")
      table += "</td></tr>"
    end
    table += "</tbody>"

    table += "</table>"
    table
  end
end
