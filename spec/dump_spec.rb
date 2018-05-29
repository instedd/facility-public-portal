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
         "address" => "Lorem 123",
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
         "address" => "Ipsum 456",
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
    export = dump_and_read(dataset).index_by { |f| f["id"].to_i }

    f1 = export[1]
    f1_services_en = f1.delete("services:en")
    f1_services_es = f1.delete("services:es")

    expect(f1).to eq({
      "id" => "1",
      "source_id" => "F1",
      "name" => "FOO",
      "lat" => "10.696144",
      "lng" => "38.370941",
      "facility_type" => "Health Center",
      "ownership"=> "Public",
      "address"=>"Lorem 123",
      "contact_name" => "John Doe",
      "contact_email" => "john@example.com",
      "contact_phone" => "123",
      "location_1" => "Amhara",
      "location_2" => "North Wello",
      "location_3" => "Bugna"
    })
    expect(f1_services_en.split(",").sort).to eq(["Child vaccination", "Iron Tablets"])
    expect(f1_services_es.split(",").sort).to eq(["Tabletas de hierro", "Vacunación de menores"])

    expect(export[2]).to eq({
      "id" => "2",
      "source_id" => "F2",
      "name" => "BAR",
      "lat" => "10.696144",
      "lng" => "38.370941",
      "facility_type" => "Hospital",
      "ownership" => "Private",
      "address" => "Ipsum 456",
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
    export = dump_and_read(dataset, [:en], 1)
    expect(export.size).to eq(2)
  end


  it "drops separators in service names" do
    # workaround. we should escape the separator but seems like overkill.
    dataset = {
      facilities: [
       {
         "id" => "F1",
         "name" => "FOO",
         "lat" => 10.696144,
         "lng" => 38.370941,
         "location_id" => "L1",
         "ownership" => "Public",
         "facility_type" => "Health Center",
         "contact_name" => "John Doe",
         "contact_email" => "john@example.com",
         "contact_phone" => "123",
         "last_update" => nil
       }
     ],
     services: [
       {"id" => "S1", "name:en" => "Foo,Bar"},
       {"id" => "S2", "name:en" => "Baz"}
     ],
     facilities_services: [
       { "facility_id" => "F1", "service_id" => "S1" },
       { "facility_id" => "F1", "service_id" => "S2" }
     ],
     locations: [{"id" => "L1", "name" => "Amhara", "parent_id" => "-----------------"}],
     facility_types: []
    }

    export = dump_and_read(dataset, [:en])

    expect(export.first["services:en"].split(",").sort).to eq(["Baz", "FooBar"])
  end

  def dump_and_read(dataset, locales = [:en, :es], page_size = 100)
    output_io = StringIO.new

    index_dataset(dataset, locales)
    dump_dataset(output_io, page_size, locales)

    CSV.parse(output_io.string, headers: true, converters: [:blank_to_nil])
       .map(&:to_h)
  end

end
