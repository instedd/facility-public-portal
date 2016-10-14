class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  skip_before_action :verify_authenticity_token, only: :report_facility

  def map
    @js_flags = {
      "initialPosition" => [8.979787, 38.758917],
      "fakeUserPosition" => Rails.env.development? || !ENV['FAKE_USER_POSITION'].blank?
    }
  end

  def report_facility
    facility = ElasticsearchService.instance.get_facility(params[:id])
    facility_name = facility["name"]
    report = JSON.parse(request.body.read)
    ApplicationMailer.facility_report(facility_name, report).deliver
    head :ok
  end
end
