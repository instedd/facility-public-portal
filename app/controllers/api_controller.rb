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

    results = ElasticsearchService.instance.facilities_around(lat, lng)
    render json: results
  end
end
