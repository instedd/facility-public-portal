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
          "Admin_health_hierarchy" => "938E631B-5EE7-42D1-976A-04D26334CE4F",
          "facility_type" => "health_center",
          "ownership" => "gov_public",
          "pocname" => "John Doe",
          "facility__official_phone_number" => "456787654",
          "facility__official_email" => "jdoe@example.org",
          "general_services" => "growth_monitoring, hiv_care_support",
          "last updated" => "Tue, 11 Oct 2016 07:19:08 +0000"
        },
        {
          "resmap-id" => 1021322,
          "name" => "2 Fero Health Center",
          "lat" => 6.86437,
          "long" => 38.47822,
          "Admin_health_hierarchy" => "938E631B-5EE7-42D1-976A-04D26334CE4F",
          "facility_type" => "health_post",
          "ownership" => "priv",
          "pocname" => "",
          "facility__official_phone_number" => "",
          "facility__official_email" => "",
          "general_services" => "lab_dx",
          "last updated" => ""
        },
        {
          "resmap-id" => 1021323,
          "name" => "3 Fero Health Center",
          "lat" => 6.96437,
          "long" => 38.47822,
          "Admin_health_hierarchy" => "938E631B-5EE7-42D1-976A-04D26334CE4F",
          "facility_type" => "health_post",
          "ownership" => "priv",
          "pocname" => "",
          "facility__official_phone_number" => "",
          "facility__official_email" => "",
          "general_services" => "lab_dx",
          "last updated" => ""
        },
        {
          "resmap-id" => 435,
          "name" => "To be ignored",
          "lat" => nil,
          "long" => nil,
          "Admin_health_hierarchy" => "1F38BF47-0955-48F0-AA57-4A5E97006850",
          "facility_type" => "health_post",
          "last updated" => ""
        }
      ],
      fields: [
        {
          "fields" => [
            { "code" => "facility_type",
              "config" => {
                "hierarchy" => [
                  {
                    "id" => "health_center",
                    "name" => "Health Center"
                  },
                  {
                    "id" => "health_post",
                    "name" => "Health Post"
                  }
                ]
              }
            },
            {
              "code" => "ownership",
              "kind" => "hierarchy",
              "config" => {
                "hierarchy" => [
                  {
                    "id" => "gov",
                    "name" => "Government",
                    "sub" => [
                      {
                        "id" => "gov_public",
                        "name" => "Public"
                      }
                    ]
                  },
                  {
                    "id" => "priv",
                    "name" => "Private"
                  }
                ]
              }
            },
            { "code" => "general_services",
              "config" => {
                "options" => [
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
                  }
                ]
              }
            }
          ]
        },
        {
          "fields" => [
            { "code" => "Admin_health_hierarchy",
              "config" => {
                "hierarchy" => [
                  { "id" => "CB4135DA-3059-4D93-BBD8-C0564CEE1A6A",
                    "name" => "Ethiopia",
                    "sub" => [
                      { "id" => "9203F461-AF75-40D3-BCFE-1CEEE788BD9E",
                        "name" => "Somali Region",
                        "sub" => [
                          { "id" => "938E631B-5EE7-42D1-976A-04D26334CE4F",
                            "name" => "Jijiga Zone",
                          }
                        ]
                      },
                      { "id" => "1F38BF47-0955-48F0-AA57-4A5E97006850",
                        "name" => "Harari Region",
                      }
                    ]
                  }
                ]
              }
            }
          ]
        }
      ]
    }

    photo_of_facility = lambda { |f| "photo/#{f["resmap-id"]}.jpg" }
    result = ResmapNormalization.new(dataset, photo_of_facility: photo_of_facility).run

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
          photo: "photo/1021321.jpg",
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
          photo: "photo/1021322.jpg",
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
          photo: "photo/1021323.jpg",
          last_update: "",
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

