class ApiController < ActionController::Base
  protect_from_forgery with: :exception
  before_filter :set_locale

  def search
    search_result = ElasticsearchService.instance.search_facilities(search_params)

    render json: { items: search_result[:items] }.tap { |h|
      h[:next_url] = search_path(search_params.merge({from: search_result[:next_from]})) if search_result[:next_from]
    }
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

  def facility_types
    render json: ElasticsearchService.instance.get_facility_types
  end

  private

  def search_params
    params.permit(:q, :s, :l, :t, :o, :lat, :lng, :size, :from)
  end

  def set_locale
    begin
      # if params or cookies are broken let's go with the default_locale
      I18n.locale = params[:locale] || cookies[:locale] || http_accept_language.compatible_language_from(I18n.available_locales)
    rescue
      I18n.locale = I18n.default_locale
    end
  end
end
