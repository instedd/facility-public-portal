require "csv"

CSV::Converters[:blank_to_nil] ||= lambda do |field|
  field && field.empty? ? nil : field
end

CSV::Converters[:spa_input_blanks] ||= lambda do |field|
  if field && field.empty?
    nil
  elsif field == "NULL" || field == "Unavilable" || field == "Unavailable"
    nil
  else
    field
  end
end
