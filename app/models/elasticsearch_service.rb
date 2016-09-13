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
            name: {type: 'string'},
            position: {type: 'geo_point'}
          }
        }
      }
    })
  end

  def index_facility(facility)
    raise "Invalid facility" unless is_valid?(facility)

    client.index({
      index: @index_name,
      type: 'facility',
      id: facility["id"],
      body: {
        name: facility["name"],
        type: facility["type"],
        position: {
          lat: facility["lat"],
          lon: facility["lng"]
        }
      }
    })
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
    ["name", "type", "lat", "lng"].none? { |field| facility[field].empty? }
  end

end
