require 'uuidtools'

module ResourceMap
  class SiteNormalizer
    attr_reader :facilities, 
                :locations, 
                :categories, 
                :category_groups, 
                :services, 
                :facility_categories, 
                :facility_services,
                :facility_types,
                :sites_with_missing_data_count
  
    def initialize(output_dir)
      @facilities = {}
      @locations = {}
      @categories = {}
      @category_groups = {}
      @services = {}
      @facility_categories = []
      @facility_services = []
      @facility_types = [{ "name" => "Institution", "priority" => 1}] #TODO: define facility types
  
      @output_dir = output_dir
      FileUtils.mkdir_p(@output_dir)
  
      @sites_with_missing_data_count = 0
    end
  
    def parse_site(site, locale)
      properties = site["properties"]
      facility = extract_facility(site, properties)
      if facility.nil?
        log_missing_data("Missing coordinates for site #{site["id"]}: #{site["name"]}")
        return
      end
      
      facility_id = facility["id"] 
      @facilities[facility_id] = facility
  
      facility["location_id"] = extract_location_hierarchy(properties, @locations)
      facility["facility_type"] = "Institution"
  
      facility_category_id = extract_category(properties, @categories, @category_groups, locale)
      log_missing_data("Missing category for site #{site["id"]}: #{site["name"]}") if facility_category_id.nil?
  
      @facility_categories << { "facility_id" => facility_id, "category_id" => facility_category_id } unless facility_category_id.nil?
  
      service_ids = extract_services(properties, @services, locale)
      service_ids.each do |service_id|
        @facility_services << { "facility_id" => facility_id, "service_id" => service_id }
      end
    end
  
    def write_csvs
      write_csv(File.join(@output_dir, "facilities.csv"), @facilities.values)
      write_csv(File.join(@output_dir, "categories.csv"), @categories.values)
      write_csv(File.join(@output_dir, "category_groups.csv"), @category_groups.values)
      write_csv(File.join(@output_dir, "locations.csv"), @locations.values)
      write_csv(File.join(@output_dir, "services.csv"), @services.values)
      write_csv(File.join(@output_dir, "facility_categories.csv"), @facility_categories)
      write_csv(File.join(@output_dir, "facility_services.csv"), @facility_services)
      write_csv(File.join(@output_dir, "facility_types.csv"), @facility_types)
    end
  
    private
  
    def log_missing_data(message)
      File.open(File.join(@output_dir, "missing_data.log"), "a") do |f|
        f.puts message
        @sites_with_missing_data_count += 1
      end
    end
  
    def write_csv(filename, data)
      CSV.open(filename, "w") do |csv|
        csv << data.first.keys
        data.each { |row| csv << row.values }
      end
    end
  
    def generate_unique_id(name)
      UUIDTools::UUID.sha1_create(UUIDTools::UUID_OID_NAMESPACE, name).to_s if name.presence 
    end
  
    def extract_location_hierarchy(properties, locations)
      return nil if properties.nil?
    
      parent_ids = {}
      lowest_level_id = nil
      
      properties.each do |key, value|
        next unless key.start_with?("admin_div-")
        
        level = key.split('-').last.to_i
        location_id = generate_unique_id(value)
        
        locations[location_id] ||= {
          "id" => location_id,
          "name" => value,
          "parent_id" => parent_ids[level - 1], # Parent from previous level
        }
        
        parent_ids[level] = location_id
        lowest_level_id = location_id
      end
      
      lowest_level_id
    end
  
    def extract_services(properties, services, locale)
      service_ids = []
    
      properties.each do |key, value|
        if key.start_with?("services_", "clinicalservices_")
          service_id = generate_unique_id(value)
          
          unless services.key?(service_id)
            services[service_id] = { "id" => service_id, "name:#{locale}" => value }
          end
          
          service_ids << service_id
        end
      end
      
      service_ids
    end
  
    def extract_category(properties, categories, category_groups, locale)
      category_name = properties["fac_type-2"] || properties["fac_type-1"]
      return unless category_name
      category_id = generate_unique_id(category_name)
      category_group_name = properties["fac_ type-2"] ? properties["fac_type-1"] : category_name
      category_group_id = generate_unique_id(category_group_name)
      
      # Create or find the category
      unless categories.has_key?(category_id)
        categories[category_id] = {
          "id" => category_id,
          "category_group_id" => nil, # To be updated later
          "name:#{locale}" => category_name
        }
      end
  
      # Create or find the category group
      unless category_groups.has_key?(category_group_name)
        category_groups[category_group_id] = {
        "id" => category_group_id,
        "name:#{locale}" => category_group_name
      }
      end
      
      # Link category to its category group
      categories[category_id]["category_group_id"] = category_group_id
      
      category_id
    end
  
    def extract_facility(site, properties)
      facility = {}
      facility["id"] = site["id"] # Will be stored in the source_id field
      facility["name"] = site["name"]
      facility["lat"] = site["lat"]
      return nil if facility["lat"].nil?
      facility["lng"] = site["long"]
      return nil if facility["lng"].nil?
      facility["ownership"] = properties["ownership"].presence
      facility["contact_name"] = properties["incharge_name"].presence 
      facility["contact_email"] = properties["incharge_email"].presence || properties["officialemail"].presence
      facility["contact_phone"] = properties["officermobilenumber"].presence || properties["incharge_mobile"].presence || properties["officialphone"].presence
      facility["last"] = nil # TODO
      facility["photo"] = nil # TODO
      facility
    end
  end
end