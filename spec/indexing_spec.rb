require 'rails_helper'

include Helpers

RSpec.describe Indexing do
  describe "validations" do
    before (:context) { reset_index }

    let(:valid_dataset) do
      {facilities: [
         {
           id: "F1",
           name: "FOO",
           lat: 10.696144,
           lng: 38.370941,
           location_id: "L1",
           facility_type: "Health Center",
           contact_name: "",
           contact_email: nil,
           contact_phone: nil,
           last_update: nil
         }
       ],
       services: [],
       facilities_services: [],
       locations: [{id: "L1", name: "Ethiopia", parent_id: "-----------------"},],
       facility_types: []
      }
    end

    it "skips facilities without a name" do
      index_dataset({facilities: [
                       {
                         id: "INVALID",
                         name: nil,
                         lat: 10.696144,
                         lng: 38.370941,
                         location_id: "L1",
                         facility_type: "Health Center",
                         contact_name: "",
                         contact_email: nil,
                         contact_phone: nil,
                         last_update: nil
                       }
                     ],
                     services: [],
                     facilities_services: [],
                     locations: [{id: "L1", name: "Ethiopia", parent_id: "-----------------"},],
                     facility_types: []
                    })

      expect(all_facilities).to be_empty
    end

    it "skips facilities without facility_type" do
      index_dataset({facilities: [
                       {
                         id: "INVALID",
                         name: "FOO",
                         lat: 10.696144,
                         lng: 38.370941,
                         location_id: "L1",
                         facility_type: nil,
                         contact_name: "",
                         contact_email: nil,
                         contact_phone: nil,
                         last_update: nil
                       }
                     ],
                     services: [],
                     facilities_services: [],
                     locations: [{id: "L1", name: "Ethiopia", parent_id: "-----------------"},],
                     facility_types: []
                    })

      expect(all_facilities).to be_empty
    end

    it "skips facilities without lat/lng" do
      index_dataset({facilities: [
                       {
                         id: "INVALID1",
                         name: "FOO",
                         lat: nil,
                         lng: 38.370941,
                         location_id: "L1",
                         facility_type: "Health Center",
                         contact_name: "",
                         contact_email: nil,
                         contact_phone: nil,
                         last_update: nil
                       },
                       {
                         id: "INVALID2",
                         name: "FOO",
                         lat: 10.696144,
                         lng: nil,
                         location_id: "L1",
                         facility_type: "Health Center",
                         contact_name: "",
                         contact_email: nil,
                         contact_phone: nil,
                         last_update: nil
                       }
                     ],
                     services: [],
                     facilities_services: [],
                     locations: [{id: "L1", name: "Ethiopia", parent_id: "-----------------"},],
                     facility_types: []
                    })

      expect(all_facilities).to be_empty
    end

    it "indexes a valid facility" do
      index_dataset(valid_dataset)

      expect(all_facilities.size).to eq(1)
    end

    describe "facility type priority" do
      context "priority is not explicit in the dataset" do
        it "assigns minimum value" do
          index_dataset(valid_dataset)

          facility = all_facilities[0]
          expect(facility["facility_type_priority"]).to eq(0)
        end
      end

      context "priority is explicit in the dataset" do
        it "assigns the value" do
          index_dataset(valid_dataset.tap do |ds|
                          ds[:facility_types] = [ { name: "Health Center", priority: 3 } ]
                        end)

          facility = all_facilities[0]
          expect(facility["facility_type_priority"]).to eq(3)
        end
      end
    end
  end

  def all_facilities
    result = elasticsearch_service.client.search index: TESTING_INDEX, type: 'facility'
    result["hits"]["hits"].map { |hit| hit["_source"] }
  end
end
