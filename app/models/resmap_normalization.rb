require "csv"

class ResmapNormalization

  def initialize(dataset, photo_of_facility: nil)
    @dataset = dataset
    @photo_of_facility = photo_of_facility
  end

  def run
    @sites_ignored = 0

    # index facility types by id
    # count number of facility types to determine priority
    @facility_types = field_options("facility_type").to_a
    @facility_types.each { |type| type[:count] = 0 }
    @facility_types_by_code = @facility_types.index_by { |type| type[:id] }

    {}.tap do |result|
      result[:facilities_services] = []

      result[:facilities] = @dataset[:sites].reduce([]) do |facilities, f|
        if f["lat"].blank? || f["long"].blank?
          @sites_ignored += 1
        else
          id = f["resmap-id"].to_s

          fac_type = @facility_types_by_code[f["facility_type"]]
          fac_type[:count] += 1

          facilities << {
            id: id,
            name: f["name"],
            lat: f["lat"],
            lng: f["long"],
            location_id: f["administrative_boundaries"],
            facility_type: fac_type[:name],
            ownership: [f["managing_authority-1"], f["managing_authority-2"]].select(&:present?).join(" - "),
            contact_name: nil_if_empty(f["pocname"]),
            contact_email: f["poc_email"],
            contact_phone: f["poc_phonenumber"],
            photo: @photo_of_facility.try { |pof| pof.call(f) },
            last_update: f["last updated"]
          }

          f["general_services"].split(",").each do |service|
            result[:facilities_services] << { facility_id: id, service_id: service.strip }
          end
        end

        facilities
      end

      result[:locations] = field_hierarchy("administrative_boundaries")

      result[:services] = field_options("general_services")

      @facility_types.sort_by! { |type| -type[:count] }
      result[:facility_types] = @facility_types.map.with_index(1) do |type,i|
        { name: type[:name], priority: i }
      end
    end
  end

  def stats
    puts "#{@sites_ignored} sites ignored"
    puts ""
    puts "sites imported"
    @facility_types.each do |type|
      puts "#{type[:name]}: #{type[:count]}"
    end
  end

  def nil_if_empty(v)
    v.empty? ? nil : v
  end

  def field_hierarchy(code)
    hierarchy = field_config(code)["hierarchy"]
    res = []
    fill_hierarchy(res, hierarchy, "")
    res
  end

  def fill_hierarchy(target, input, parent_id)
    input.each do |node|
      target << { id: node["id"], name: node["name"], parent_id: parent_id }

      if node["sub"]
        fill_hierarchy(target, node["sub"], node["id"])
      end
    end
  end

  def field_options(code)
    options = field_config(code)["options"]
    options.map { |opt|
      {id: opt["code"], name: opt["label"] }
    }
  end

  def field_config(code)
    @dataset[:fields].each do |layer|
      layer["fields"].each do |field|
        return field["config"] if field["code"] == code
      end
    end
    raise "no field for code #{code}"
  end
end
