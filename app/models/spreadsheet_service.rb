require 'google/apis/sheets_v4'

class SpreadsheetService
  def self.get_data(spreadsheet_id)
    service = Google::Apis::SheetsV4::SheetsService.new
    service.key = ENV['GOOGLE_SHEET_API_KEY']

    begin 
      sheet = service.get_spreadsheet(spreadsheet_id)
      # A1 notation: range == 'All Cells' 
      range = sheet.sheets[0].properties.title
      response = service.get_spreadsheet_values(spreadsheet_id, range)
    rescue Exception => e
      raise ActionController::BadRequest.new(), e.message()
    end

    rows = response.values

    Enumerator.new do |enum|
      rows.each do |row|
        enum << row
      end
    end
  end
end
