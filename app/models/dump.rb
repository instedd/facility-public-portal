require "zip"

class Dump

  def initialize(output_path, service, page_size, locales)
    @output_path = output_path
    @service = service
    @page_size = page_size
    @locales = locales
  end


  def run
    max_administrative_level = @service.max_administrative_level

    CSV.open(@output_path, "wb") do |csv|
      csv << ["id", "name", "lat", "lng", "facility_type", "ownership", "contact_name", "contact_email", "contact_phone"] \
              + (1..max_administrative_level).map { |l| "location_#{l}" } \
              + @locales.map { |locale| "services:#{locale}" }

      from = 0
      loop do
        page = @service.dump_facilities(from: from, size: @page_size)

        page[:items].each do |f|
          csv << [
            f["id"],
            f["name"],
            f["lat"],
            f["lng"],
            f["facility_type"],
            f["ownership"],
            f["contact_name"],
            f["contact_email"],
            f["contact_phone"],
          ] \
          + pad_right(f["adm"], max_administrative_level) \
          + @locales.map { |l| f["service_names:#{l}"].join("|") }
        end

        break unless page[:next_from]
        from = page[:next_from]
      end
    end
  end

  def self.dump(output_path)
    self.new(output_path, ElasticsearchService.instance, 200, Settings.locales.keys).run
  end

  def self.dump_zip(output_path)
    csv_file = Tempfile.new("out")
    self.dump(csv_file.path)

    Zip::File.open(output_path, Zip::File::CREATE) do |zipfile|
      zipfile.add("facilities.csv", csv_file.path)
    end
  end

  private

  def pad_right(array, length)
    ret = array
    (length - array.length).times do
      ret << nil
    end
    ret
  end
end
