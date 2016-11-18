require 'rails_helper'

RSpec.describe ResmapNormalization do
  it "generates normalized schema" do
    dataset = {
      sites: [
        {
          "resmap-id" => 1021321,
          "name" => "1 Fero Health Center",
          "lat" => 6.76437,
          "long" => 38.47822,
          "administrative_boundaries" => "938E631B-5EE7-42D1-976A-04D26334CE4F",
          "facility_type" => "health_center",
          "managing_authority" => "gov_public",
          "managing_authority-1" => "Government",
          "managing_authority-2" => "Public",
          "pocname" => "John Doe",
          "poc_phonenumber" => "456787654",
          "poc_email" => "jdoe@example.org",
          "general_services" => "growth_monitoring, hiv_care_support",
          "last updated" => "Tue, 11 Oct 2016 07:19:08 +0000"
        },
        {
          "resmap-id" => 1021322,
          "name" => "2 Fero Health Center",
          "lat" => 6.86437,
          "long" => 38.47822,
          "administrative_boundaries" => "938E631B-5EE7-42D1-976A-04D26334CE4F",
          "facility_type" => "health_post",
          "managing_authority" => "priv",
          "managing_authority-1" => "Private",
          "managing_authority-2" => "",
          "pocname" => "",
          "poc_phonenumber" => "",
          "poc_email" => "",
          "general_services" => "lab_dx",
          "last updated" => ""
        },
        {
          "resmap-id" => 1021323,
          "name" => "3 Fero Health Center",
          "lat" => 6.96437,
          "long" => 38.47822,
          "administrative_boundaries" => "938E631B-5EE7-42D1-976A-04D26334CE4F",
          "facility_type" => "health_post",
          "managing_authority" => "priv",
          "managing_authority-1" => "Private",
          "managing_authority-2" => "",
          "pocname" => "",
          "poc_phonenumber" => "",
          "poc_email" => "",
          "general_services" => "lab_dx",
          "last updated" => ""
        },
        {
          "resmap-id" => 435,
          "name" => "To be ignored",
          "lat" => nil,
          "long" => nil,
          "administrative_boundaries" => "1F38BF47-0955-48F0-AA57-4A5E97006850",
          "facility_type" => "health_post",
          "last updated" => ""
        }
      ],
      locations: [
        {
          "ID" => "CB4135DA-3059-4D93-BBD8-C0564CEE1A6A",
          "ParentID" => "",
          "ItemName" => "Ethiopia",
        },
        {
          "ID" => "9203F461-AF75-40D3-BCFE-1CEEE788BD9E",
          "ParentID" => "CB4135DA-3059-4D93-BBD8-C0564CEE1A6A",
          "ItemName" => "Somali Region",
        },
        {
          "ID" => "938E631B-5EE7-42D1-976A-04D26334CE4F",
          "ParentID" => "9203F461-AF75-40D3-BCFE-1CEEE788BD9E",
          "ItemName" => "Jijiga Zone",
        },
        {
          "ID" => "1F38BF47-0955-48F0-AA57-4A5E97006850",
          "ParentID" => "CB4135DA-3059-4D93-BBD8-C0564CEE1A6A",
          "ItemName" => "Harari Region",
        },
      ],
      facility_types: [
        {
          "code" => "health_center",
          "id" => 13,
          "label" => "Health Center"
        },
        {
          "code" => "health_post",
          "id" => 14,
          "label" => "Health Post"
        }
      ],
      general_services: [
        {
          "code" => "growth_monitoring",
          "id" => 1,
          "label" => "Growth Monitoring"
        },
        {
          "code" => "curativecare_u5",
          "id" => 2,
          "label" => "Curative Care u5"
        },
        {
          "code" => "hiv_care_support",
          "id" => 11,
          "label" => "HIV Care and Support"
        },
        {
          "code" => "lab_dx",
          "id" => 13,
          "label" => "Laboratory Diagnostics"
        },
      ]
    }

    result = ResmapNormalization.new(dataset).run

    expect(result).to eq({
      facilities: [
        {
          id: "1021321",
          name: "1 Fero Health Center",
          lat: 6.76437,
          lng: 38.47822,
          location_id: "938E631B-5EE7-42D1-976A-04D26334CE4F",
          facility_type: "Health Center",
          ownership: "Government - Public",
          contact_name: "John Doe",
          contact_phone: "456787654",
          contact_email: "jdoe@example.org",
          last_update: "Tue, 11 Oct 2016 07:19:08 +0000"
        },
        {
          id: "1021322",
          name: "2 Fero Health Center",
          lat: 6.86437,
          lng: 38.47822,
          location_id: "938E631B-5EE7-42D1-976A-04D26334CE4F",
          facility_type: "Health Post",
          ownership: "Private",
          contact_name: nil,
          contact_phone: "",
          contact_email: "",
          last_update: ""
        },
        {
          id: "1021323",
          name: "3 Fero Health Center",
          lat: 6.96437,
          lng: 38.47822,
          location_id: "938E631B-5EE7-42D1-976A-04D26334CE4F",
          facility_type: "Health Post",
          ownership: "Private",
          contact_name: nil,
          contact_phone: "",
          contact_email: "",
          last_update: ""
        }
      ],
      locations: [
        {
          id: "CB4135DA-3059-4D93-BBD8-C0564CEE1A6A",
          name: "Ethiopia",
          parent_id: "",
        },
        {
          id: "9203F461-AF75-40D3-BCFE-1CEEE788BD9E",
          name: "Somali Region",
          parent_id: "CB4135DA-3059-4D93-BBD8-C0564CEE1A6A",
        },
        {
          id: "938E631B-5EE7-42D1-976A-04D26334CE4F",
          name: "Jijiga Zone",
          parent_id: "9203F461-AF75-40D3-BCFE-1CEEE788BD9E",
        },
        {
          id: "1F38BF47-0955-48F0-AA57-4A5E97006850",
          name: "Harari Region",
          parent_id: "CB4135DA-3059-4D93-BBD8-C0564CEE1A6A",
        },
      ],
      services: [
        { id: "growth_monitoring", name: "Growth Monitoring" },
        { id: "curativecare_u5", name: "Curative Care u5" },
        { id: "hiv_care_support", name: "HIV Care and Support" },
        { id: "lab_dx", name: "Laboratory Diagnostics" },
      ],
      facilities_services: [
        { facility_id: "1021321", service_id: "growth_monitoring" },
        { facility_id: "1021321", service_id: "hiv_care_support" },
        { facility_id: "1021322", service_id: "lab_dx" },
        { facility_id: "1021323", service_id: "lab_dx" }
      ],
      facility_types: [
        # facility types priority are given according to # of facilities of that type
        { name: "Health Post", priority: 1 },
        { name: "Health Center", priority: 2 },
      ],
    })
  end
end
