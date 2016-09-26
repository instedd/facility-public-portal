require 'rails_helper'

RSpec.describe ElasticsearchService do

  TESTING_INDEX = "fpp-test"

  before(:all) do
    @service = ElasticsearchService.new("localhost", TESTING_INDEX, should_log: ENV["ELASTICSEARCH_LOG"])
  end

  def reset_index
    @service.drop_index rescue nil
    @service.setup_index
    @service.setup_mappings
  end

  before(:context) do
    reset_index

    Indexer.index_records([{
                             'resmap-id' => 1,
                             'name' => "1st Wetanibo Balchi",
                             'facility_type' => "Health Center",
                             'lat' => 8.958315,
                             'long' => 38.761659,
                             'service_codes' => ["s1", "s2"],
                             'administrative_boundaries-1' => "Ethiopia",
                             'administrative_boundaries-2' => "Snnp Region",
                             'administrative_boundaries-3' => "Gurage Zone",
                           },
                           {
                             'resmap-id' => 2,
                             'name' => "Abaferet Health Center",
                             'facility_type' => "Health Center",
                             'lat' => 10.696144,
                             'long' => 38.370941,
                             'service_codes' => ["s2", "s3"],
                             'administrative_boundaries-1' => "Ethiopia",
                             'administrative_boundaries-2' => "Snnp Region",
                             'administrative_boundaries-3' => "Hadiya Zone",
                           }
                          ], @service)

    @service.client.indices.refresh index: TESTING_INDEX
  end

  describe "search" do
    describe "by name" do
      it "searches by word prefix" do
        search_assert({ q: "Wet" }, expected_ids: [1])
      end

      it "searches by inner words" do
        search_assert({ q: "Bal" }, expected_ids: [1])
      end
    end

    describe "by service" do
      it "works!" do
        search_assert({ s: 1 }, expected_ids: [1])
        search_assert({ s: 2 }, expected_ids: [1, 2])
        search_assert({ s: 3 }, expected_ids: [2])
      end
    end

    describe "by administrative location" do
      it "works!" do
        search_assert({ l: 1 }, expected_ids: [1,2])
        search_assert({ l: 2 }, expected_ids: [1,2])
        search_assert({ l: 3 }, expected_ids: 1)
        search_assert({ l: 4 }, expected_ids: 2)
      end
    end

    describe "sorting by user location" do
      it "works!" do
        search_assert({ lat: 8.959169, lng: 38.827452 }, expected_ids: [1, 2])
        search_assert({ lat: 10.622245, lng: 38.646663 }, expected_ids: [2, 1])
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
          results = @service.suggest_services("s#{i}")
          expect(results.map { |s| s['id'] }).to eq([i])
        end
      end
    end

    describe "locations" do
      it "works" do
        results = @service.suggest_locations("Hadi")
        expect(results.size).to eq(1)

        results[0].tap do |r|
          expect(r["id"]).to eq(4)
          expect(r["name"]).to eq("Hadiya Zone")
          expect(r["facility_count"]).to eq(1)
          expect(r["parent_name"]).to eq("Snnp Region")
        end
      end
    end
  end

  def search_assert(params, expected_ids:, order_matters: false)
    results = @service.search_facilities(params)
    actual_ids = results.map { |r| r['id'] }
    if order_matters
      expect(actual_ids).to eq(expected_ids)
    else
      expect(actual_ids).to match_array(expected_ids)
    end
  end
end
