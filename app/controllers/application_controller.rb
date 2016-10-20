class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

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

  def set_js_flags
    @js_flags = {
      "initialPosition" => [Settings.initial_position.lat, Settings.initial_position.lng],
      "fakeUserPosition" => (params[:user_position] || Settings.user_position) == "fake",
      "contactEmail" => Settings.report_email_to
    }
  end
end
