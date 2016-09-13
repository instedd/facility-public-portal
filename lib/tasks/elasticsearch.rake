namespace :elasticsearch do
  desc 'Initializes the elasticsearch index'
  task init_index: :environment do
    ElasticsearchService.instance.init_index
  end

  desc 'Initializes the elasticsearch mappings'
  task init_mappings: :environment do
    ElasticsearchService.instance.init_mappings
  end

  desc 'Initializes the elasticsearch index and mappings'
  task init: [:init_index, :init_mappings]
end
