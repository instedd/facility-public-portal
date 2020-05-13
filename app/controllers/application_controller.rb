class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :set_locale
  before_action :set_js_flags

  skip_before_action :verify_authenticity_token, only: :report_facility
  rescue_from ActionController::BadRequest, with: :bad_request

  def map
    @js_flags.merge!({
      "menuItem" => :map,
      "initialPosition" => [Settings.initial_position.lat, Settings.initial_position.lng],
      "mapBounds" => [
        [Settings.map_bounds.top, Settings.map_bounds.left],
        [Settings.map_bounds.bottom, Settings.map_bounds.right]
      ],
      "mapZoom" => Settings.map_zoom.to_h,
      "fakeUserPosition" => (params[:user_position] || Settings.user_position) == "fake",
      "mapboxId" => Settings.mapbox_id,
      "mapboxToken" => Settings.mapbox_token,
      "locales" => Settings.locales,
      "locale" => I18n.locale,
      "facilityTypes" => ElasticsearchService.instance.get_facility_types,
      "ownerships" => ElasticsearchService.instance.get_ownerships,
      "categoryGroups" => ElasticsearchService.instance.get_category_groups,
      "facilityPhotos" => Settings.facility_photos
    })
  end

  def report_facility
    facility = ElasticsearchService.instance.get_facility(params[:id])
    facility_name = facility["name"]
    report = JSON.parse(request.body.read)
    #TODO send on background
    ApplicationMailer.facility_report(facility_name, report).deliver
    head :ok
  end

  protected

  def set_js_flags
    @js_flags = {
      "authenticated" => user_signed_in?,
      "contactEmail" => Settings.report_email_to,
      "menuItem" => ""
    }
  end

  def set_locale
    begin
      # if params or cookies are broken let's go with the default_locale
      I18n.locale = params[:locale] || cookies[:locale] || http_accept_language.compatible_language_from(I18n.available_locales)
    rescue
      I18n.locale = I18n.default_locale
    end
    cookies[:locale] = I18n.locale
  end

  def bad_request(exception)
    render status: 400, json: {:error => exception.message}.to_json 
  end
end
