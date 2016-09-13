class ApiController < ActionController::Base
  protect_from_forgery with: :exception

  def suggest
    query = params[:q]
    results = ElasticsearchService.instance.facilities_around(9.002507, 38.747244)

    render json: results
  end
end
