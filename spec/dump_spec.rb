require 'rails_helper'

include Helpers

RSpec.describe Dump do

  before (:each) { reset_index }

  let(:dataset) do
    {
      facilities: [
       {
         "id" => "F1",
         "name" => "FOO",
         "lat" => 10.696144,
         "lng" => 38.370941,
         "location_id" => "L3",
         "ownership" => "Public",
         "facility_type" => "Health Center",
         "contact_name" => "John Doe",
         "contact_email" => "john@example.com",
         "contact_phone" => "123",
         "last_update" => nil
       },
       {
         "id" => "F2",
         "name" => "BAR",
         "lat" => 10.696144,
         "lng" => 38.370941,
         "location_id" => "L4",
         "ownership" => "Private",
         "facility_type" => "Hospital",
         "contact_name" => nil,
         "contact_email" => nil,
         "contact_phone" => nil,
         "last_update" => nil
       }
     ],
     services: [
       {"id" => "S1", "name:en" => "Iron Tablets", "name:es" => "Tabletas de hierro" },
       {"id" => "S2", "name:en" => "Child vaccination", "name:es" => "Vacunación de menores" }
     ],
     facilities_services: [
       { "facility_id" => "F1", "service_id" => "S1" },
       { "facility_id" => "F1", "service_id" => "S2" },
       { "facility_id" => "F2", "service_id" => "S1" },
     ],
     locations: [
       {"id" => "L1", "name" => "Amhara", "parent_id" => "-----------------"},
       {"id" => "L2", "name" => "North Wello", "parent_id" => "L1"},
       {"id" => "L3", "name" => "Bugna", "parent_id" => "L2"},
       {"id" => "L4", "name" => "Kobo", "parent_id" => "L2"},
     ],
     facility_types: []
    }
  end

  it "generates flat csv dump of current facilities" do
    export = dump_and_read

    f1 = export[1]
    f1_services_en = f1.delete("services:en")
    f1_services_es = f1.delete("services:es")

    expect(f1).to eq({
      "id" => "1",
      "name" => "FOO",
      "lat" => "10.696144",
      "lng" => "38.370941",
      "facility_type" => "Health Center",
      "ownership"=> "Public",
      "contact_name" => "John Doe",
      "contact_email" => "john@example.com",
      "contact_phone" => "123",
      "location_1" => "Amhara",
      "location_2" => "North Wello",
      "location_3" => "Bugna"
    })
    expect(f1_services_en.split("|").sort).to eq(["Child vaccination", "Iron Tablets"])
    expect(f1_services_es.split("|").sort).to eq(["Tabletas de hierro", "Vacunación de menores"])

    expect(export[2]).to eq({
      "id" => "2",
      "name" => "BAR",
      "lat" => "10.696144",
      "lng" => "38.370941",
      "facility_type" => "Hospital",
      "ownership" => "Private",
      "contact_name" => nil,
      "contact_email" => nil,
      "contact_phone" => nil,
      "location_1" => "Amhara",
      "location_2" => "North Wello",
      "location_3" => "Kobo",
      "services:en"=> "Iron Tablets",
      "services:es" => "Tabletas de hierro"
    })
  end

  it "pages elasticsearch results if needed" do
    export = dump_and_read(1)
    expect(export.size).to eq(2)
  end

  def dump_and_read(page_size = 100)
    locales = [:en, :es]
    output_file = Tempfile.new("out")

    index_dataset(dataset, locales)
    dump_dataset(output_file.path, page_size, locales)

    CSV.read(output_file.path, headers: true, converters: [:blank_to_nil])
       .map(&:to_h)
       .index_by { |f| f["id"].to_i }
  end

end
