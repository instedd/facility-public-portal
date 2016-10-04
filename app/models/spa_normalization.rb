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
          name: f["FacilityName"],
          lat: latlng["Latitude"],
          lng: latlng["Longitude"],
          location_id: f["OrganizationUnitId"],
          facility_type: types[f["FacilityTypeId"]]["FacilityTypeName"],
          contact_name: full_name.empty? ? nil : full_name,
          contact_email: contact["Email"],
          contact_phone: contact["Telephone"],
          last_update: nil # TODO
        }
      end

      result[:services] = @dataset[:services].map do |s|
        {
          id: s["Id"],
          name: s["ServiceTypeName"],
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
          name: (l["OfficialName"] || l["OffcialName"]).titleize,
          parent_id: l["ParentId"],
        }
      end
    end
  end

end
