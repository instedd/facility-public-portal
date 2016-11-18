require "csv"

class ResmapNormalization

  def initialize(dataset)
    @dataset = dataset
  end

  def run
    @sites_ignored = 0

    @facility_types = @dataset[:facility_types].map(&:to_h).index_by { |type| type["code"] }
    @facility_types.each do |k, v|
      v[:count] = 0
    end

    {}.tap do |result|
      result[:facilities_services] = []

      result[:facilities] = @dataset[:sites].reduce([]) do |facilities, f|
        if f["lat"].blank? || f["long"].blank?
          @sites_ignored += 1
        else
          id = f["resmap-id"].to_s
          fac_type = @facility_types[f["facility_type"]]
          fac_type[:count] += 1

          facilities << {
            id: id,
            name: f["name"],
            lat: f["lat"],
            lng: f["long"],
            location_id: f["administrative_boundaries"],
            ownership: [f["managing_authority-1"], f["managing_authority-2"]].select(&:present?).join(" - "),
            facility_type: fac_type["label"],
            contact_name: nil_if_empty(f["pocname"]),
            contact_email: f["poc_email"],
            contact_phone: f["poc_phonenumber"],
            last_update: f["last updated"]
          }

          f["general_services"].split(",").each do |service|
            result[:facilities_services] << { facility_id: id, service_id: service.strip }
          end
        end

        facilities
      end

      result[:locations] = @dataset[:locations].map do |l|
        {
          id: l["ID"],
          name: l["ItemName"],
          parent_id: l["ParentID"],
        }
      end

      result[:services] = @dataset[:general_services].map do |s|
        {
          id: s["code"],
          name: s["label"],
        }
      end

      sorted_types = @facility_types.values.to_a
      sorted_types.sort_by! { |v| v[:count] }
      result[:facility_types] = sorted_types.map.with_index(1) do |t,i|
        { name: t["label"], priority: i }
      end
    end
  end

  def stats
    puts "#{@sites_ignored} sites ignored"
    puts ""
    puts "sites imported"
    sorted_types = @facility_types.values.to_a
    sorted_types.sort_by! { |v| v[:count] }
    sorted_types.each do |t|
      puts "#{t["label"]}: #{t[:count]}"
    end
  end

  def nil_if_empty(v)
    v.empty? ? nil : v
  end
end
