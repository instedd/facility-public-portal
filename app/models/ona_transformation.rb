require "csv"

class OnaTransformation
  MAPPING_HEADERS = {
    'category_id' => 0,
    'data_column' => 1,
    'true values' => 2,
    'false values' => 3
  }.freeze

  def self.read_csv(path)
    csv_enumerator(path)
  end

  def self.invalid_data_column(column_name)
    ArgumentError.new "I can't find column '#{column_name}' in ONA data file."
  end

  def self.validate_mapping_headers!(headers)
    if headers.map{|h| h.downcase } == MAPPING_HEADERS.keys
      return headers
    else
      raise ArgumentError.new(
        "I don't understand this mapping file. I expect its headers to be exactly: #{MAPPING_HEADERS.keys.to_s}\n" ++
        "Instead, it was: #{headers.to_s}")
    end
  end

  def self.validate_facility_headers!(headers)
    raise ArgumentError.new("ONA data.csv file must have a '_id' column containing the facility ids.") unless headers.map{|h| h.downcase}.include?("_id")
    headers
  end

  def self.facility_id_column_index(headers)
    headers.find_index "_id"
  end

  def self.facility_categories(facility_data, categories, mappings)
    facility_categories = [["facility_id", "category_id"]]

    facility_headers = []
    facility_id_index = nil
    mapping_headers = []

    facility_data.each_with_index do |facility_row, f_index|
      if f_index == 0
        facility_headers = validate_facility_headers!(facility_row)
        facility_id_index = facility_id_column_index(facility_row)
      else
        mappings.each_with_index do |m, m_index|
          if m_index == 0
            mapping_headers = validate_mapping_headers!(m) if mapping_headers.length == 0
          else
            data_column = m[MAPPING_HEADERS["data_column"]]
            data_column_index = facility_headers.find_index data_column

            raise invalid_data_column(data_column) unless data_column_index

            mapping_value = facility_row[data_column_index]

            true_values = (m[MAPPING_HEADERS["true values"]] || "").split(',')
            false_values = (m[MAPPING_HEADERS["false values"]] || "").split(',')

            false_match = false
            false_values.each do |false_v|
              false_match = false_match || mapping_value.include?(false_v)
            end

            if !false_match
              true_match = false
              true_values.each do |true_v|
                true_match = true_match || mapping_value.include?(true_v)
              end

              if true_values.length == 0 || true_match
                facility_categories.push [facility_row[facility_id_index], m[MAPPING_HEADERS["category_id"]]]
              end
            end
          end
        end
      end
    end

    facility_categories
  end

  def self.csv_enumerator(path)
    Enumerator.new do |out|
      encoding = "utf-8"
      encoding = "bom|utf-8" if file_with_bom?(path)

      CSV.foreach(path, headers: false, encoding: encoding, converters: [:blank_to_nil, :numeric]) do |row|
        out << row
      end
    end
  end

  def self.file_with_bom?(path)
    File.open(path).each_byte.take(3) == [0xEF, 0xBB, 0xBF]
  end
end