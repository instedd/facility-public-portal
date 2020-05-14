require "open3"
require "fileutils"

class DatasetsController < ApplicationController
  before_action :authenticate_user!
  before_action { @js_flags["menuItem"] = :datasets }
  layout "content"

  def import
    run_import_process("#{Rails.root}/bin/import-dataset #{Rails.root.join(Settings.input_dir).to_s}")
  end

  def import_ona
    run_import_process("#{Rails.root}/bin/end-to-end-import #{Rails.root.join(Settings.input_dir).to_s}")
  end

  def upload
    validate_upload_params
    filename = (params["file"] && params["file"].original_filename) || params["name"]
    FileUtils.mkdir_p DatasetsChannel.directory_for(filename)

    if params["url"] 
      sheetId = sheet_id_match(params["url"])
      range = SpreadsheetService.get_range(sheetId)

      run_upload_from_google_sheet_process("#{Rails.root}/bin/upload-from-google-sheet #{filename} #{sheetId} #{range}")
    else
      if params["file"] 
        File.open(DatasetsChannel.path_for(filename), 'wb') do |file|
          file.write(params[:file].read)
        end
      end
      DatasetsChannel.dataset_update
      render json: :ok
    end
  end

  def download
    requested_file = "#{params[:filename]}.csv"

    # Set MIME type to */* to avoid browsers complaining with
    # "Resource interpreted as Document but transferred with MIME type text/csv"
    send_file(DatasetsChannel.path_for(requested_file), filename: requested_file, type: '*/*')
  end

  private

  def run_import_process(cmd)
    stdin, stdout, stderr, wait_thr = Open3.popen3(cmd)
    pid = SecureRandom.uuid
    Thread.new do
      loop do
        ready = IO.select([stdout, stderr]).first
        r = ready.each do |io|
          data = io.read_nonblock(1024, exception: false)
          next if data == :wait_readable
          break :eof unless data
          DatasetsChannel.import_log(pid, data)
        end
        break if r == :eof
      end
      [stdin, stdout, stderr].each &:close
      DatasetsChannel.import_complete(pid, wait_thr.value.exitstatus)
    end
    render json: { process_id: pid }
  end

  def run_upload_from_google_sheet_process(cmd)
    stdin, stdout, stderr, wait_thr = Open3.popen3(cmd)
    pid = SecureRandom.uuid
    Thread.new do
      loop do
        ready = IO.select([stdout, stderr]).first
        r = ready.each do |io|
          data = io.read_nonblock(1024, exception: false)
          next if data == :wait_readable
          break :eof unless data
        end
        break if r == :eof
      end
      [stdin, stdout, stderr].each &:close
      DatasetsChannel.dataset_update
    end
    render json: { process_id: pid }
  end

  def validate_upload_params
    if params["file"] 
      raise ActionController::BadRequest.new(), "Invalid file" unless params["file"].original_filename
    else
      raise ActionController::BadRequest.new(), "Invalid url or filename" unless params["url"] && params["name"]
      raise ActionController::BadRequest.new(), "Missing SheetId in url" unless sheet_id_match(params["url"])
    end
  end

  def sheet_id_match(url)
    match = url.match /^.*\/d\/(?<sheetId>.*)\/.*$/
    match && match[:sheetId]
  end
end
