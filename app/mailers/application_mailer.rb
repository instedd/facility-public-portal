class ApplicationMailer < ActionMailer::Base
  default from: 'from@example.com'
  layout 'mailer'

  def facility_report(facility, report)
    mail_address = "example@example.com"
    @facility = facility
    @report = report
    mail(to: mail_address, subject: "Facility report for #{@facility}")
  end
end
