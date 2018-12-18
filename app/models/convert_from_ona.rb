class ConvertFromOna

  attr_accessor :logger

  def initialize(dataset, input_path, output_path)
    @dataset = dataset
    @input_path = input_path
    @output_path = output_path

    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end

  def csv_headers
    ["id", "name", "lat", "lng", "location_id", "facility_type", "ownership", "address", "contact_name", "contact_email", "contact_phone", "opening_hours:en", "opening_hours:fr", "photo", "last_updated"]
  end

  def convert
    logger.info "Convert process started!"

    data = []

    data << csv_headers

    @dataset[:ona_source].each do |line|
      data << [line["_id"],
        line["section1/section1.1/facility_name"],
        line["section1/section1.1/_general_gps_coordinates_latitude"],
        line["section1/section1.1/_general_gps_coordinates_longitude"],
        line["section1/section1.1/city"],
        "laboratory",
        line["section1/section1.1/Laboratory_affiliation"],
        line["section1/section1.1/laboratory_adress"],
        line["section1/section1.1/contact_name"]
      ]
    end

    # id = _id
    # name = section1/section1.1/facility_name
    # lat = section1/section1.1/_general_gps_coordinates_latitude
    # lng = section1/section1.1/_general_gps_coordinates_longitude
    # location_id = section1/section1.1/city
    # facility_type = "laboratory"
    # ownership = section1/section1.1/Laboratory_affiliation
    # address = section1/section1.1/laboratory_adress
    # contact_name = section1/section1.1/contact_name
    # contact_email = section1/section1.1/contact_email
    # contact_phone = section1/section1.1/contact_phone
    # opening_hours:en =
    # opening_hours:fr =
    # photo = null
    # last_updated = end_time

    write_csv(data)

    logger.info "Done!"
  end

  def write_csv(data)
    CSV.open("#{@output_path}/facilities.csv", "wb", quote_char: '"') do |csv|
      data.each do |line|
        csv << line
      end
    end
  end

  def self.convert_dataset(dataset, input_path, output_path)
    process = self.new(dataset, input_path, output_path)
    process.convert
  end

  def self.read_csv_dataset(csv_files_path)
    {
      ona_source: csv_enumerator(File.join(csv_files_path, "onaSource.csv")),
    }
  end

  def self.csv_enumerator(path)
    Enumerator.new do |out|
      encoding = "utf-8"
      encoding = "bom|utf-8" if file_with_bom?(path)

      CSV.foreach(path, headers: true, encoding: encoding, converters: [:blank_to_nil, :numeric]) do |row|
        out << row
      end
    end
  end

  def self.file_with_bom?(path)
    File.open(path).each_byte.take(3) == [0xEF, 0xBB, 0xBF]
  end

end
