class ApiController < ActionController::Base
  protect_from_forgery with: :exception

  def suggest
    query = params[:q]

    lat = params[:lat]
    lng = params[:lng]

    if !lat || !lng
      # Center of Addis Ababa
      lat, lng = 8.979787, 38.758917
    end

    results = {
      facilities: ElasticsearchService.instance.search_facilities(query, lat, lng),
      services: ElasticsearchService.instance.search_services(query)
    }
    render json: results
  end
end
