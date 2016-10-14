require 'rails_helper'

include Helpers

RSpec.describe ElasticsearchService do

  before(:context) do
    reset_index

    index_dataset({facilities: [
                     {
                       id: "F1",
                       name: "1st Wetanibo Balchi",
                       lat: 8.958315,
                       lng: 38.761659,
                       location_id: "L3",
                       facility_type: "Health Center",
                       contact_name: "",
                       contact_email: nil,
                       contact_phone: nil,
                       last_update: nil
                     },
                     {
                       id: "F2",
                       name: "Abaferet Health Center",
                       lat: 10.696144,
                       lng: 38.370941,
                       location_id: "L4",
                       facility_type: "Health Center",
                       contact_name: "",
                       contact_email: nil,
                       contact_phone: nil,
                       last_update: nil
                     }
                   ],

                   services: [
                     { id: "S1", name: "service1" },
                     { id: "S2", name: "service2" },
                     { id: "S3", name: "service3" }
                   ],

                   facilities_services: [
                     {facility_id: "F1", service_id: "S1"},
                     {facility_id: "F1", service_id: "S2"},

                     {facility_id: "F2", service_id: "S2"},
                     {facility_id: "F2", service_id: "S3"}
                   ],

                   facility_types: [],

                   locations: [
                     {id: "L1", name: "Ethiopia", parent_id: "-----------------"},
                     {id: "L2", name: "Snnp Region", parent_id: "L1"},
                     {id: "L3", name: "Gurage Zone", parent_id: "L2"},
                     {id: "L4", name: "Hadiya Zone", parent_id: "L2"}
                   ]})
  end

  describe "search" do
    describe "by name" do
      it "searches by word prefix" do
        search_assert({ q: "Wet" }, expected_ids: ["F1"])
      end

      it "searches by inner words" do
        search_assert({ q: "Bal" }, expected_ids: ["F1"])
      end
    end

    describe "by service" do
      it "works!" do
        search_assert({ s: 1 }, expected_ids: ["F1"])
        search_assert({ s: 2 }, expected_ids: ["F1", "F2"])
        search_assert({ s: 3 }, expected_ids: ["F2"])
      end
    end

    describe "by administrative location" do
      it "works!" do
        search_assert({ l: 1 }, expected_ids: ["F1","F2"])
        search_assert({ l: 2 }, expected_ids: ["F1","F2"])
        search_assert({ l: 3 }, expected_ids: "F1")
        search_assert({ l: 4 }, expected_ids: "F2")
      end
    end

    describe "sorting by user location" do
      it "works!" do
        search_assert({ lat: 8.959169, lng: 38.827452 }, expected_ids: ["F1", "F2"])
        search_assert({ lat: 10.622245, lng: 38.646663 }, expected_ids: ["F2", "F1"])
      end
    end
  end

  describe "suggestions" do
    describe "facilities" do
      # TODO: same as searchiing for the moment...
    end

    describe "services" do
      it "works" do
        [1,2,3].each do |i|
          results = elasticsearch_service.suggest_services("service#{i}")
          expect(results.map { |s| s['source_id'] }).to eq(["S#{i}"])
        end
      end
    end

    describe "locations" do
      it "works" do
        results = elasticsearch_service.suggest_locations("Hadi")
        expect(results.size).to eq(1)

        results[0].tap do |r|
          expect(r["source_id"]).to eq("L4")
          expect(r["name"]).to eq("Hadiya Zone")
          expect(r["facility_count"]).to eq(1)
          expect(r["parent_name"]).to eq("Snnp Region")
        end
      end
    end
  end

  def search_assert(params, expected_ids:, order_matters: false)
    results = elasticsearch_service.search_facilities(params)[:items]
    actual_ids = results.map { |r| r['source_id'] }
    if order_matters
      expect(actual_ids).to eq(expected_ids)
    else
      expect(actual_ids).to match_array(expected_ids)
    end
  end
end
