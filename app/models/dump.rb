class Dump

  def initialize(params, output_io, service, page_size, locales)
    @params = params
    @output_io = output_io
    @service = service
    @page_size = page_size
    @locales = locales
  end


  def run
    max_administrative_level = @service.max_administrative_level

    append_csv_line ["id", "source_id", "name", "lat", "lng", "facility_type", "ownership", "address", "contact_name", "contact_email", "contact_phone"] \
              + (1..max_administrative_level).map { |l| "location_#{l}" } \
              + @locales.map { |locale| "services:#{locale}" }

    @params.delete(:from)
    @params.delete(:size)

    from = 0
    loop do
      page = @service.dump_facilities({from: from, size: @page_size}.merge!(@params).with_indifferent_access)

      page[:items].each do |f|
        append_csv_line [
          f["id"],
          f["source_id"],
          f["name"],
          f["lat"],
          f["lng"],
          f["facility_type"],
          f["ownership"],
          f["address"],
          f["contact_name"],
          f["contact_email"],
          f["contact_phone"],
        ] \
        + pad_right(f["adm"], max_administrative_level) \
        + @locales.map { |l|
            f["service_names:#{l}"].map { |n| n.gsub(",", "") }
                                  .join(",")
          }
      end

      break unless page[:next_from]
      from = page[:next_from]
    end
  end

  def self.dump(params, output_io)
    self.new(params, output_io, ElasticsearchService.instance, 200, Settings.locales.keys).run
  end

  private

  def pad_right(array, length)
    ret = array
    (length - array.length).times do
      ret << nil
    end
    ret
  end

  def append_csv_line(data)
    @output_io.write CSV.generate_line(data, force_quotes: true)
  end
end
