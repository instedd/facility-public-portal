require "csv"

class ResmapNormalization

  def initialize(dataset)
    @dataset = dataset
  end

  def run
    @sites_ignored = 0

    types = @dataset[:facility_types].index_by { |type| type["code"] }

    {}.tap do |result|
      result[:facilities] = @dataset[:sites].reduce([]) do |facilities, f|
        if f["lat"].blank? || f["long"].blank?
          @sites_ignored += 1
        else
          facilities << {
            id: f["resmap-id"].to_s,
            name: f["name"],
            lat: f["lat"],
            lng: f["long"],
            location_id: f["administrative_boundaries"],
            ownership: [f["managing_authority-1"], f["managing_authority-2"]].select(&:present?).join(" - "),
            facility_type: types[f["facility_type"]]["label"],
            contact_name: nil_if_empty(f["pocname"]),
            contact_email: f["poc_email"],
            contact_phone: f["poc_phonenumber"],
            last_update: f["last updated"]
          }
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
    end
  end

  def stats
    puts "#{@sites_ignored} sites ignored"
  end

  def nil_if_empty(v)
    v.empty? ? nil : v
  end
end
