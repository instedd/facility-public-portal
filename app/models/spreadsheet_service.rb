require 'google/apis/sheets_v4'

class SpreadsheetService
  def self.get_data(spreadsheet_id)
    service = Google::Apis::SheetsV4::SheetsService.new
    service.key = ENV['GOOGLE_SHEET_API_KEY']

    range='Sheet1'
    response1 = service.get_spreadsheet_values(spreadsheet_id, range)
    response2 = service.get_spreadsheet_values(spreadsheet_id, range)

    res = { "items" => [], "config" => {} }
    headers = []

    response1.values.each_with_index do |row, i|
      if i == 0
        headers = row
      else
        item = {}
        row.each_with_index do |cell,j|
          item[headers[j]] = cell
        end
        res["items"] << item unless item.empty?
      end
    end

    response2.values.each do |row|
      res["config"][row[0]] = row[1]
    end

    res
  end
end
