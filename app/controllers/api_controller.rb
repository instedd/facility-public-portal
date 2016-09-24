class ApiController < ActionController::Base
  protect_from_forgery with: :exception

  def search
    render json: ElasticsearchService.instance.search_facilities(params)
  end

  def suggest
    service = ElasticsearchService.instance
    query = params[:q]

    results = {
      facilities: service.suggest_facilities(params),
      services: service.suggest_services(query),
      locations: service.suggest_locations(query)
    }
    render json: results
  end

  def get_facility
    id = params[:id].to_i
    render json: ElasticsearchService.instance.get_facility(id)
  end
end
