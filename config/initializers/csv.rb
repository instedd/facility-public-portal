require "csv"

CSV::Converters[:blank_to_nil] ||= lambda do |field|
  field && field.empty? ? nil : field
end
