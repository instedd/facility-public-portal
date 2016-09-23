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

    index_facilities([
                       {
                         'resmap-id' => 1,
                         'name' => "1st Wetanibo Balchi",
                         'facility_type' => "Health Center",
                         'lat' => 8.958315,
                         'long' => 38.761659,
                         'service_codes' => ["s1", "s2"],
                         'administrative_boundaries-1' => "adm1",
                         'administrative_boundaries-2' => "adm2",
                         'administrative_boundaries-3' => "adm3",
                       },
                       {
                         'resmap-id' => 2,
                         'name' => "Abaferet Health Center",
                         'facility_type' => "Health Center",
                         'lat' => 10.696144,
                         'long' => 38.370941,
                         'service_codes' => ["s2", "s3"],
                         'administrative_boundaries-1' => "adm1",
                         'administrative_boundaries-2' => "adm2",
                         'administrative_boundaries-3' => "adm4",
                       }
                     ])

    @service.client.indices.refresh index: TESTING_INDEX
  end

  describe "searching by name" do
    it "searches by word prefix" do
      search_assert({ q: "Wet" }, expected_ids: [1])
    end

    it "searches by inner words" do
      search_assert({ q: "Bal" }, expected_ids: [1])
    end
  end

  describe "searching by service" do
    it "works!" do
      search_assert({ s: 1 }, expected_ids: [1])
      search_assert({ s: 2 }, expected_ids: [1, 2])
      search_assert({ s: 3 }, expected_ids: [2])
    end
  end

  describe "sorting by user location" do
    it "works!" do
      search_assert({ lat: 8.959169, lng: 38.827452 }, expected_ids: [1, 2])
      search_assert({ lat: 10.622245, lng: 38.646663 }, expected_ids: [2, 1])
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

  def index_facilities(facilities)
    service_codes = facilities.flat_map { |f| f['service_codes'] }.uniq

    services = service_codes.map.with_index do |code, i|
      {
        id: i+1,
        name: code,
        code: code,
        facility_count: 0
      }
    end

    services_by_code = services.index_by { |s| s[:code] }

    facilities.each { |f| @service.index_facility(f.with_indifferent_access, services_by_code) }
    services.each { |s| @service.index_service(s) }
  end

end
