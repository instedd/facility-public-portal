require "csv"

class SpaNormalization

  def initialize(dataset)
    @dataset = dataset
  end

  def run
    {}.tap do |result|
      coordinates = @dataset[:geoloc].index_by { |geoloc| geoloc["Id"] }
      types = @dataset[:facility_types].index_by { |type| type["Id"] }
      contact_info = @dataset[:contact_info].index_by { |type| type["Id"] }

      result[:facilities] = @dataset[:facilities].map do |f|
        latlng = coordinates[f["GeographicCoordinateId"]] || {}
        contact = contact_info[f["ContactInformationId"]] || {}
        full_name = [contact["FirstName"], contact["MiddleName"], contact["LastName"]].compact.join(" ")

        {
          id: f["Id"],
          name: f["FacilityName"].try(:titleize).try(:strip),
          lat: latlng["Latitude"],
          lng: latlng["Longitude"],
          location_id: f["OrganizationUnitId"],
          facility_type: types[f["FacilityTypeId"]]["FacilityTypeName"].strip,
          contact_name: full_name.empty? ? nil : full_name.strip,
          contact_email: contact["Email"].try(:strip),
          contact_phone: contact["Telephone"].try(:strip),
          last_update: nil # TODO
        }
      end

      result[:services] = @dataset[:services].map do |s|
        {
          id: s["Id"],
          name: s["ServiceTypeName"].strip,
        }
      end

      result[:facilities_services] = @dataset[:facilities_services].map do |assoc|
        {
          facility_id: assoc["FacilityId"],
          service_id: assoc["MedicalServiceId"],
        }
      end

      result[:locations] = @dataset[:locations].map do |l|
        {
          id: l["Id"],
          name: (l["OfficialName"] || l["OffcialName"]).titleize.strip,
          parent_id: l["ParentId"],
        }
      end

      result[:facility_types] = [
        { name: "Health Center", priority: 1 },
        { name: "Primary Hospital", priority: 2 },
        { name: "General Hospital", priority: 3 },
        { name: "Referral Hospital", priority: 4 },
      ]
    end
  end

end
