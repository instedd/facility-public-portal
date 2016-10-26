class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_filter :set_locale

  skip_before_action :verify_authenticity_token, only: :report_facility
  before_action :set_js_flags

  def map
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

  def set_locale
    begin
      # if params or cookies are broken let's go with the default_locale
      I18n.locale = params[:locale] || cookies[:locale] || http_accept_language.compatible_language_from(I18n.available_locales)
    rescue
      I18n.locale = I18n.default_locale
    end
    cookies[:locale] = I18n.locale
  end

  def set_js_flags
    @js_flags = {
      "initialPosition" => [Settings.initial_position.lat, Settings.initial_position.lng],
      "fakeUserPosition" => (params[:user_position] || Settings.user_position) == "fake",
      "contactEmail" => Settings.report_email_to,
      "mapboxId" => Settings.mapbox_id,
      "mapboxToken" => Settings.mapbox_token,
      "locales" => Settings.locales,
      "locale" => I18n.locale,
      "facilityTypes" => ElasticsearchService.instance.get_facility_types
    }
  end
end
