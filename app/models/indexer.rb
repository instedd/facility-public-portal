require "csv"

class Indexer

  def initialize(records, service)
    @records = records.map(&:with_indifferent_access)
    @service = service
    @imported_facilities = 0
    @imported_services = 0
    @imported_locations = 0

    @batch_size = ENV['INDEXING_BATCH_SIZE'] || 100
  end

  def run
    services_by_code = build_services_by_code(@records)

    locations_by_id = build_locations_by_id(@records)
    locations_by_path = locations_by_id.values.index_by { |l| l[:path_names] }

    @records.each_slice(@batch_size) do |group|
      batch = []

      facilities = group.each do |record|
        facility = build_facility(record, services_by_code, locations_by_path)

        record[:service_codes].each do |code|
          services_by_code[code][:facility_count] += 1
        end

        facility[:adm_ids].each do |id|
          locations_by_id[id][:facility_count] += 1
        end

        @imported_facilities += 1

        batch << facility
      end

      @service.index_facility_batch(batch)
    end

    locations_by_id.values.each_slice(@batch_size) do |locations|
      @service.index_location_batch locations
      @imported_locations += locations.size
    end

    services_by_code.values.each_slice(@batch_size) do |services|
      @service.index_service_batch services
      @imported_services += services.size
    end

    {imported_facilities: @imported_facilities, imported_services: @imported_services, imported_locations: @imported_locations}
  end

  private

  def build_services_by_code(records)
    service_codes = []
    @records.each do |record|
      record[:service_codes].each do
        |s| service_codes << s
      end
    end

    services = service_codes.uniq.map.with_index do |code, i|
      {
        id: i+1,
        name: code.gsub(/__+/, " - ").gsub("_", " ").strip.capitalize,
        code: code,
        facility_count: 0
      }
    end

    services.index_by { |s| s[:code] }
  end

  def build_locations_by_id(records)
    location_paths = []
    @records.each do |record|
      path = (1..4).map { |i| record[:"administrative_boundaries-#{i}"] }.compact

      (1..4).each do |size|
        location_paths << path.take(size)
      end
    end
    location_paths.uniq!
    build_location_tree(location_paths)
  end

  def build_location_tree(location_paths)
    locations_by_id = {}

    # assign an id to each location path
    _, ids_by_path = location_paths.inject([1,{}]) do |(next_id, ret), path|
      ret[path] = next_id
      [next_id+1, ret]
    end

    # start with leafs and go up building the location objects
    location_paths.sort { |p| -p.size }.each do |path|
      path = path.dup

      while path != []
        id = ids_by_path[path]

        # stop if parent has already been traversed up to the top
        break if locations_by_id[id]

        locations_by_id[id] = {
          id: id,
          name: path.last,
          path_names: path.dup,
          parent_id: ids_by_path[path.take(path.size-1)],
          parent_name: (path[-2] rescue nil),
          facility_count: 0,
        }

        path.pop(1)
      end
    end

    # once we have the references in each location, build the path of parent ids
    locations_by_id.each do |id, loc|
      path_ids = [loc[:id]]

      p_id = loc[:parent_id]
      while p_id
        path_ids << p_id
        parent = locations_by_id[p_id]
        p_id = parent[:parent_id]
      end

      loc[:path_ids] = path_ids.reverse
    end

    locations_by_id
  end

  def build_facility(record, services_by_code, locations_by_path)
    adm = [
      record["administrative_boundaries-1"],
      record["administrative_boundaries-2"],
      record["administrative_boundaries-3"],
      record["administrative_boundaries-4"]
    ].compact

    {
      id: record[:'resmap-id'].to_i,
      name: record[:name],
      kind: record[:facility_type],
      position: {
        lat: record[:lat],
        lon: record[:long]
      },
      service_names: record[:service_codes].map { |c| services_by_code[c][:name]},
      service_ids: record[:service_codes].map { |c| services_by_code[c][:id]},
      adm1: record["administrative_boundaries-1"],
      adm2: record["administrative_boundaries-2"],
      adm3: record["administrative_boundaries-3"],
      adm4: record["administrative_boundaries-4"],
      adm: adm,
      adm_ids: locations_by_path[adm][:path_ids],
      report_to: record["report_to"],
      contact_email: record["poc_email"],
      contact_phone: record["poc_phonenumber"],
      contact_name: record["pocname"],
      last_updated: record["last updated"].try(:to_i)
    }
  end

  def self.valid_csv_row?(row)
    ["name", "facility_type", "lat", "long", "last updated"].none? { |field| row[field].blank? }
  end

  def self.index_csv(filename, service = ElasticsearchService.instance)
    records = Enumerator.new do |out|
      CSV.foreach(filename, headers: true, converters: [:blank_to_nil]) do |row|
        if valid_csv_row? row
          record = row.to_h.with_indifferent_access
          services_str = record.delete(:services)
          record[:service_codes] = services_str ? services_str.split("|") : []
          record[:'last updated'] = DateTime.parse(record[:'last updated'])
          out << record
        end
      end
    end

    self.new(records,service).run
  end

  def self.index_records(records, service)
    self.new(records, service).run
  end
end
