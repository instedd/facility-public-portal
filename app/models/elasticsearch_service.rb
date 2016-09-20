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

  def search_facilities(params)
    validate_search(params)

    search_body = {
      size: 50,
      query: {},
      sort: {}
    }

    if params[:q]
      search_body[:query][:match_phrase_prefix] = { name: params[:q] }
    end

    if params[:service]
    end

    if params[:lat] && params[:lng]
      search_body[:sort] = {
        _geo_distance: {
          position: {
            lat: params[:lat],
            lon: params[:lng]
          },
          order: "asc",
          unit:  "km",
          distance_type: "plane"
        }
      }
    end

    if params[:count]
      search_body[:size] = params[:count]
    end

    result = client.search({
      index: @index_name,
      type: 'facility',
      body: search_body
    })

    result["hits"]["hits"].map { |r| r["_source"] }
  end

  def get_facility(id)
    result = client.search({
      index: @index_name,
      type: 'facility',
      body: {
        size: 1,
        query: {
          match: {id: id}
        },
    }})

    result["hits"]["hits"].first["_source"]
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

  private

  def validate_search(params)
    # TODO
  end

end
