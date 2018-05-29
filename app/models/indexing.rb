class Indexing

  attr_accessor :logger

  MANDATORY_FIELDS = ["name", "facility_type", "lat", "lng"]

  def initialize(dataset, service, locales)
    @dataset = dataset
    @service = service
    @locales = locales

    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO

    @last_facility_id = 0
    @last_facility_type_id = 0
    @last_ownership_id = 0
    @last_service_id = 0
    @last_location_id = 0

    @validation_results = Hash.new(0)
  end

  def run
    logger.info "Indexing process started!"

    logger.info "Calculating services by id"
    services_by_id = @dataset[:services].index_by { |s| s["id"] }.map_values do |s|
      h = s.to_h.symbolize_keys
      h[:source_id] = h[:id]
      h[:id] = @last_service_id += 1
      h[:facility_count] = 0

      validate_service_translations(h)
      h
    end

    logger.info "Calculating locations by id"
    locations_by_id = @dataset[:locations].index_by { |l| l["id"] }.map_values do |l|
      h = l.to_h.symbolize_keys
      h[:source_id] = h[:id]
      h[:id] = @last_location_id += 1
      h[:facility_count] = 0
      h
    end

    logger.info "Calculating services by facility"
    services_by_facility = @dataset[:facilities_services]
                           .group_by   { |assoc| assoc["facility_id"].to_s }
                           .map_values { |assocs| assocs.map { |a| services_by_id[a["service_id"]] } }

    logger.info "Calculating full location paths"
    locations_by_id.values.each do |l|
      path_ids = []
      path_names = []

      next_loc = l

      loop do
        path_ids << next_loc[:id]
        path_names << next_loc[:name]

        next_loc = locations_by_id[next_loc[:parent_id]]
        break unless next_loc
      end

      l[:path_ids] = path_ids.reverse
      l[:level] = path_ids.length
      l[:path_names] = path_names.reverse

      if parent = locations_by_id[l[:parent_id]]
        l[:parent_name] = parent[:name]
      end
    end

    facility_types = @dataset[:facility_types].map { |t|
      t = t.to_h.symbolize_keys
      t[:id] = (@last_facility_type_id += 1)
      t
    }.index_by { |type| type[:name] }

    ownerships = @dataset[:facilities].map { |f| f["ownership"] }
                 .uniq
                 .compact
                 .map { |o| { id: (@last_ownership_id += 1), name: o }}
                 .index_by { |o| o[:name] }

    logger.info "Indexing facilities"

    valid = validate_facilities(@dataset[:facilities])

    valid.each_slice(100) do |batch|
      index_entries = batch.map do |f|
        f = f.to_h.symbolize_keys

        location = locations_by_id[f[:location_id]]
        unless location
          location = {path_names: [], path_ids: [], facility_count: 0}
        end
        location[:facility_count] += 1

        services = services_by_facility[f[:id].to_s] || []
        services.sort_by! { |s| s[:name] }
        services.each { |s| s[:facility_count] +=1 }

        type = facility_types[f[:facility_type]]

        if !type
          type = { id: (@last_facility_type_id += 1), name: f[:facility_type], priority: 0 }
          facility_types[type[:name]] = type
        end


        f = f.merge({
          id: @last_facility_id += 1,
          source_id: f[:id].to_s,
          contact_phone: f[:contact_phone] && f[:contact_phone].to_s,
          priority: type[:priority],
          facility_type_id: type[:id],
          ownership_id: f[:ownership] ? ownerships[f[:ownership]][:id] : nil,
          name: f[:name].gsub(/\u00A0/,"").strip,
          address: f[:address],
          opening_hours: localized_string(f, :opening_hours),

          position: {
            lat: f[:lat],
            lon: f[:lng],
          },

          service_ids: services.map { |s| s[:id] },

          adm: location[:path_names],
          adm_ids: location[:path_ids],

          report_to: nil, # TODO
          last_updated: nil # TODO
        })

        @locales.each do |lang|
          f["service_names:#{lang}".to_sym] = services.map { |s| s["name:#{lang}".to_sym] }.sort!
        end

        f
      end

      @service.index_facility_batch(index_entries)
    end

    logger.info "Indexing facility types"
    @service.index_facility_types(facility_types.values) unless facility_types.empty?

    logger.info "Indexing ownership types"
    @service.index_ownerships(ownerships.values) unless ownerships.empty?

    logger.info "Indexing services"
    services_by_id.values.each_slice(100) do |batch|
      @service.index_service_batch(batch.map(&:to_h))
    end

    logger.info "Indexing locations"
    locations_by_id.values.each_slice(100) do |batch|
      @service.index_location_batch(batch.map(&:to_h))
    end

    logger.info "Done!"
  end

  def self.index_dataset(dataset)
    process = self.new(dataset, ElasticsearchService.instance, Settings.locales.keys)
    process.run
    ElasticsearchService.instance.refresh_index
  end

  def self.read_csv_dataset(csv_files_path)
    csv_enumerator = Proc.new do |filename|
      (Enumerator.new do |out|
         CSV.foreach(File.join(csv_files_path, filename), headers: true, converters: [:blank_to_nil, :numeric]) do |row|
           out << row
         end
       end)
    end

    {
      facilities: csv_enumerator.call("facilities.csv"),
      services: csv_enumerator.call("services.csv"),
      facilities_services: csv_enumerator.call("facilities_services.csv"),
      facility_types: csv_enumerator.call("facility_types.csv"),
      locations: csv_enumerator.call("locations.csv"),
    }
  end

  private

  # Remove from row all field:LOCALE value and returns a hash with those values
  # { locale => value }
  def localized_string(row, field)
    res = Hash[@locales.map { |locale|
      field_in_csv = "#{field}:#{locale}".to_sym
      value = [locale, row[field_in_csv]]
      row.delete field_in_csv
      value
    }]

    res
  end

  def validate_facilities(facilities)
    valid = facilities.select { |f| validate_facility(f) }
    @validation_results.each do |field, count|
      logger.warn "Facilities ignored due to missing #{field}: #{count}"
    end
    valid
  end

  def validate_facility(facility)
    valid = true
    MANDATORY_FIELDS.each do |field|
      if facility[field].blank?
        valid = false
        @validation_results["no_#{field}".to_sym] += 1
      end
    end
    return valid
  end

  def validate_service_translations(service)
    @locales.each do |l|
      unless service["name:#{l}".to_sym]
        logger.error "Service #{service[:source_id]} doesn't have a name:#{l} field. Maybe the locale wasn't enabled when normalizing the dataset?"
        raise "Missing translation"
      end
    end
  end
end
