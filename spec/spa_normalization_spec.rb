require 'rails_helper'

RSpec.describe SpaNormalization do

  it "foo" do
    # | last update   | ???                             |
    dataset = {
      facilities: [
        {
          "Id" => "F1",
          "FacilityName" => "Berko Health Center",
          "GeographicCoordinateId" => "GC1",
          "ContactInformationId" => "CI1",
          "OrganizationUnitId" => "L2",
          "FacilityTypeId" => "T1",
        }
      ],

      facility_types: [
        "Id" => "T1",
        "FacilityTypeName" => "Health Center"
      ],

      geoloc: [
        "Id" => "GC1",
        "Latitude" => 12.22913,
        "Longitude" => 38.77668,
      ],

      contact_info: [
        "Id" => "CI1",
        "FirstName" => "Fikadu",
        "MiddleName" => "Tamicho",
        "LastName" => "Fetene",
        "Email" => "ftfetene@example.com",
        "Telephone" => "924243855",
      ],

      facilities_services: [
        {"FacilityId" => "F1", "MedicalServiceId" => "S1"},
        {"FacilityId" => "F1", "MedicalServiceId" => "S2"}
      ],

      services: [
        { "Id" => "S1", "ServiceTypeName" => "Efavirenz (efv) tablets/capsules" },
        { "Id" => "S2", "ServiceTypeName" => "Ent and ophthalmolgy equipments" }
      ],

      locations: [
        {"Id" => "L1", "OfficialName" => "Location 1", "ParentId" => "-----------------"},
        {"Id" => "L2", "OfficialName" => "Location 2", "ParentId" => "L1"}
      ],
    }

    result = SpaNormalization.new(dataset).run

    expect(result).to eq({facilities: [{
                                         id: "F1",
                                         name: "Berko Health Center",
                                         lat: 12.22913,
                                         lng: 38.77668,
                                         location_id: "L2",
                                         facility_type: "Health Center",
                                         contact_name: "Fikadu Tamicho Fetene",
                                         contact_email: "ftfetene@example.com",
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
