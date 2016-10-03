require 'rails_helper'

RSpec.describe SpaNormalization do

  it "foo" do
    # | last update   | ???                             |
    facilities = [
      {
        "Spa_Id" => "F1",
        "FacilityName" => "Berko Health Center",
        "Lat" => 12.22913,
        "Long" => 38.77668,
        "OrganizationUnitId" => "L2",
        "Facility Type" => "Health Center",
        "POC Name" => "Fikadu Fetene",
        "Email" => nil,
        "Phone Number" => "924243855",
      }
    ]

    facilities_services = [
      {"FacilityId" => "F1", "MedicalServiceId" => "S1"},
      {"FacilityId" => "F1", "MedicalServiceId" => "S2"}
    ]

    services = [
      { "Id" => "S1", "ServiceTypeName" => "Efavirenz (efv) tablets/capsules" },
      { "Id" => "S2", "ServiceTypeName" => "Ent and ophthalmolgy equipments" }
    ]

    locations  = [
      {"Id" => "L1", "OfficialName" => "Location 1", "ParentId" => "-----------------"},
      {"Id" => "L2", "OfficialName" => "Location 2", "ParentId" => "L1"}
    ]

    result = SpaNormalization.new(facilities, services, facilities_services, locations).run

    expect(result).to eq({facilities: [{
                                         id: "F1",
                                         name: "Berko Health Center",
                                         lat: 12.22913,
                                         lng: 38.77668,
                                         location_id: "L2",
                                         facility_type: "Health Center",
                                         contact_name: "Fikadu Fetene",
                                         contact_email: nil,
                                         contact_phone: "924243855",
                                         last_update: nil
                                       }],

                          services: [
                            { id: "S1", name: "Efavirenz (efv) tablets/capsules" },
                            { id: "S2", name: "Ent and ophthalmolgy equipments" }
                          ],

                          facilities_services: [
                            {facility_id: "F1", service_id: "S1"},
                            {facility_id: "F1", service_id: "S2"}
                          ],

                          locations: [
                            {id: "L1", name: "Location 1", parent_id: "-----------------"},
                            {id: "L2", name: "Location 2", parent_id: "L1"}
                          ]})

  end

end
