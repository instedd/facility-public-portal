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
      ]
    })
  end
end

