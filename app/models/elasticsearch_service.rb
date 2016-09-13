class ElasticsearchService

  attr_reader :client

  def initialize(url, index_name, should_log = Rails.env.development?)
    @client     = Elasticsearch::Client.new url: url, log: should_log
    @index_name = index_name
  end

  def init_index
    client.indices.create index: @index_name
  end

  def init_mappings
    client.indices.put_mapping({
      index: @index_name,
      type: 'facility',
      body: {
        facility: {
          properties: {
            name: {
              type: 'string',
              index: 'analyzed',
              analyzer: "standard"
            },
            position: {type: 'geo_point'}
          }
        }
      }
    })
  end

  def index_facility(facility)
    return false unless is_valid?(facility)

    client.index({
      index: @index_name,
      type: 'facility',
      id: facility["id"],
      body: {
        name: facility["name"],
        kind: facility["facility_type"],
        position: {
          lat: facility["lat"],
          lon: facility["long"]
        }
      }
    })
  end

  def facilities_around(lat, lng)
    result = client.search({
      index: @index_name,
      body: {
        sort: {
          _geo_distance: {
            position: {
              lat: lat,
              lon: lng
            },
            order: "asc",
            unit:  "km",
            distance_type: "plane"
          }
        }
    }})

    result["hits"]["hits"].map { |r| r["_source"] }
  end

  def self.instance
    @@instance ||= self.new(ENV['ELASTICSEARCH_URL'] || 'localhost',
                            ENV['ELASTICSEARCH_INDEX'] || 'fpp')
  end

  def self.client
    self.instance.client
  end

  private

  def is_valid?(facility)
    ["name", "facility_type", "lat", "long"].none? { |field| facility[field].blank? }
  end

end
