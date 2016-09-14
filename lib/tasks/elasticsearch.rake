namespace :elasticsearch do
  desc 'Initializes the elasticsearch index'
  task setup_index: :environment do
    ElasticsearchService.instance.setup_index
  end

  desc 'Initializes the elasticsearch mappings'
  task setup_mappings: :environment do
    ElasticsearchService.instance.setup_mappings
  end

  desc 'Initializes the elasticsearch index and mappings'
  task setup: [:setup_index, :setup_mappings]
end
