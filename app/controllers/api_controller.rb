class ApiController < ActionController::Base
  protect_from_forgery with: :exception

  def search
    render json: ElasticsearchService.instance.search_facilities(params)
  end

  def suggest
    query = params[:q]

    lat = params[:lat]
    lng = params[:lng]

    if !lat || !lng
      # Center of Addis Ababa
      lat, lng = 8.979787, 38.758917
    end

    results = {
      facilities: ElasticsearchService.instance.suggest_facilities(query, lat, lng),
      services: ElasticsearchService.instance.suggest_services(query)
    }
    render json: results
  end

  def get_facility
    id = params[:id].to_i
    render json: ElasticsearchService.instance.get_facility(id)
  end
end
