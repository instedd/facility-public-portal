require "csv"

class SpaNormalization

  def initialize(facilities, services, facilities_services, locations)
    @facilities = facilities
    @services = services
    @facilities_services = facilities_services
    @locations = locations
  end

  def run
    {}.tap do |result|
      result[:facilities] = @facilities.map do |f|
        {
          id: f["Spa_Id"],
          name: f["FacilityName"],
          lat: f["Lat"],
          lng: f["Long"],
          location_id: f["OrganizationUnitId"],
          facility_type: f["Facility Type"],
          contact_name: /^Unavilable/ =~ f["POC Name"] ? nil : f["POC Name"],
          contact_email: f["Email"],
          contact_phone: f["Phone Number"],
          last_update: nil # TODO
        }
      end

      result[:services] = @services.map do |s|
        {
          id: s["Id"] || s["ï»¿Id"],
          name: s["ServiceTypeName"],
        }
      end

      result[:facilities_services] = @facilities_services.map do |assoc|
        {
          facility_id: assoc["FacilityId"],
          service_id: assoc["MedicalServiceId"],
        }
      end

      result[:locations] = @locations.map do |l|
        {
          id: l["Id"] || l["ï»¿Id"],
          name: l["OfficialName"],
          parent_id: l["ParentId"],
        }
      end
    end
  end

end
