class ApplicationMailer < ActionMailer::Base
  default from: 'from@example.com'
  layout 'mailer'

  def facility_report(facility, report)
    mail_address = Settings.report_email_to
    @facility = facility
    @report = report
    mail(to: mail_address, from: Settings.report_email_from, subject: "Facility report for #{@facility}")
  end
end
