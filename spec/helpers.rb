module Helpers
  TESTING_INDEX = "fpp-test"

  def elasticsearch_service
    @service ||= ElasticsearchService.new("localhost", TESTING_INDEX, should_log: ENV["ELASTICSEARCH_LOG"])
  end

  def elasticsearch_client
    elasticsearch_service.client
  end

  def reset_index
    elasticsearch_service.drop_index rescue nil
    elasticsearch_service.setup_index
    elasticsearch_service.setup_mappings
  end

  def index_dataset(dataset)
    dataset = dataset.map_values { |records| records.map(&:with_indifferent_access) }
    process = Indexing.new(dataset, elasticsearch_service)
    process.logger.level = :unknown
    process.run

    elasticsearch_client.indices.refresh index: TESTING_INDEX
  end
end
