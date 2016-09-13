class ElasticsearchService

  def initialize(url, index_name, should_log = Rails.env.development?)
    @client     = Elasticsearch::Client.new url: url, log: should_log
    @index_name = index_name
  end

  def init_index
    @client.indices.create index: @index_name
  end

  def init_mappings
    @client.indices.put_mapping({
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

  def self.instance
    @@instance ||= self.new(ENV['ELASTICSEARCH_URL'] || 'localhost',
                            ENV['ELASTICSEARCH_INDEX'] || 'fpp')
  end
end
