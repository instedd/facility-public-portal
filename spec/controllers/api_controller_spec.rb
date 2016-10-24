require 'rails_helper'

include Helpers

RSpec.describe ApiController do
  before(:each) { reset_index }

  it "provides facility types" do
    ElasticsearchService.instance = elasticsearch_service

    index_dataset({facilities: [],
                   services: [],
                   facilities_services: [],
                   locations: [],
                   facility_types: [
                     { name: "Health Center", priority: 1 },
                     { name: "Hospital", priority: 2 }
                   ]
                  })

    get :facility_types

    expect(JSON.parse response.body).to match_array([
                                             { "id" => 1, "name" => "Health Center", "priority" => 1 },
                                             { "id" => 2, "name" => "Hospital", "priority" => 2 },
                                           ])
  end

end
