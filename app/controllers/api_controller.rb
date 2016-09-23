class ApiController < ActionController::Base
  protect_from_forgery with: :exception

  def search
    render json: ElasticsearchService.instance.search_facilities(params)
  end

  def suggest
    query = params[:q]

    results = {
      facilities: ElasticsearchService.instance.suggest_facilities(params),
      services: ElasticsearchService.instance.suggest_services(query)
    }
    render json: results
  end

  def get_facility
    id = params[:id].to_i
    render json: ElasticsearchService.instance.get_facility(id)
  end
end
