module Helpers
  TESTING_INDEX = "fpp-test"

  def elasticsearch_service
    @service ||= ElasticsearchService.new(ENV['ELASTICSEARCH_URL'] || 'localhost', TESTING_INDEX, should_log: ENV["ELASTICSEARCH_LOG"])
  end

  def elasticsearch_client
    elasticsearch_service.client
  end

  def reset_index
    elasticsearch_service.drop_index rescue nil
    elasticsearch_service.setup_index
    elasticsearch_service.setup_mappings
  end

  def index_dataset(dataset, locales = Settings.locales.keys)
    dataset = dataset.map_values { |records| records.map(&:with_indifferent_access) }
    process = Indexing.new(dataset, elasticsearch_service, locales)
    process.logger.level = :unknown
    process.run

    elasticsearch_service.refresh_index
  end

  def dump_dataset(output_io, page_size, locales = Settings.locales.keys)
    Dump.new({}, output_io, elasticsearch_service, page_size, locales).run
  end
end
