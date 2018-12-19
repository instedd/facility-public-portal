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
        line["section1/section1.1/contact_name"],
        line["section1/section1.1/contact_email"],
        line["section1/section1.1/contact_phone"],
        get_opening_hours(line, :en),
        get_opening_hours(line, :fr),
        nil,
        line["end_time"]
      ]
    end

    write_csv(data)

    logger.info "Done!"
  end

  def en_strings
    {
      :mon_thu => "Monday to Thursday",
      :mon_fri => "Monday to Friday",
      :fri => "Friday",
      :sat => "Saturday",
      :sun => "Sunday",
      :to => "to",
      :from => "from",
    }
  end

  def fr_strings
    {
      :mon_thu => "Lundi à Jeudi",
      :mon_fri => "Lundi à Vendredi",
      :fri => "Vendredi",
      :sat => "Samedi",
      :sun => "Dimanche",
      :to => "à",
      :from => "de",
    }
  end

  def get_opening_hours line, lang

    lang_strings = lang == :en ? en_strings : fr_strings

    days = line["section1/section1.1/days"]
    opening_hours_weekday = get_hours(line["section1/section1.1/open_hoursm"])
    closing_hours_weekday = get_hours(line["section1/section1.1/close_hoursm"])

    opening_hours_friday = get_hours(line["section1/section1.1/open_hoursf"])
    closing_hours_friday = get_hours(line["section1/section1.1/close_hoursf"])

    opens_saturday = days.downcase.include? "saturday"
    opens_sunday = days.downcase.include? "sunday"

    if opening_hours_weekday != opening_hours_friday || closing_hours_weekday != closing_hours_friday
      # "Monday to Thursday from #{opening_hours_weekday} to #{closing_hours_weekday}, Friday from #{opening_hours_friday} to #{closing_hours_friday}"
      result = "#{lang_strings[:mon_thu]} #{lang_strings[:from]} #{opening_hours_weekday} #{lang_strings[:to]} #{closing_hours_weekday}, #{lang_strings[:fri]} #{lang_strings[:from]} #{opening_hours_friday} #{lang_strings[:to]} #{closing_hours_friday}"
    else
      # Monday to Friday from #{opening_hours_weekday} to #{closing_hours_weekday}
      result = "#{lang_strings[:mon_fri]} #{lang_strings[:from]} #{opening_hours_weekday} #{lang_strings[:to]} #{closing_hours_weekday}"
    end

    if opens_saturday
      # Saturday from #{get_hours(line["section1/section1.1/open_hourssa"])} to #{get_hours(line["section1/section1.1/close_hourssa"])}
      result = result + ", #{lang_strings[:sat]} #{lang_strings[:from]} #{get_hours(line["section1/section1.1/open_hourssa"])} #{lang_strings[:to]} #{get_hours(line["section1/section1.1/close_hourssa"])}"
    end

    if opens_sunday
      # Sunday from #{get_hours(line["section1/section1.1/open_hourssu"])} to #{get_hours(line["section1/section1.1/close_hourssu"])}
      result = result + ", #{lang_strings[:sun]} #{lang_strings[:from]} #{get_hours(line["section1/section1.1/open_hourssu"])} #{lang_strings[:to]} #{get_hours(line["section1/section1.1/close_hourssu"])}"
    end

    result
  end

  def get_hours cell
    cell.slice(0..4)
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
