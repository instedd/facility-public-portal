class ElasticsearchService

  attr_reader :client

  def initialize(url, index_name, should_log = Rails.env.development?)
    @client     = Elasticsearch::Client.new url: url, log: should_log
    @index_name = index_name
  end

  def setup_index
    client.indices.create index: @index_name
  end

  def setup_mappings
    client.indices.put_mapping({
      index: @index_name,
      type: 'facility',
      body: {
        facility: {
          properties: {
            id: {
              type: 'long',
            },
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
    client.index({
      index: @index_name,
      type: 'facility',
      id: facility["id"],
      body: facility
    })
  end

  def index_service(service)
    client.index({
      index: @index_name,
      type: 'service',
      body: service
    })
  end

  def suggest_services(query)
    result = client.search({
      index: @index_name,
      type: 'service',
      body: {
        query: {
          match_phrase_prefix: {
            name: query
          }
        },
    }})

    result["hits"]["hits"].map { |r| r["_source"] }
  end

  def suggest_facilities(query, lat, lng, count = 5)
    result = client.search({
      index: @index_name,
      type: 'facility',
      body: {
        size: count,
        query: {
          match_phrase_prefix: {
            name: query
          }
        },
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

end
