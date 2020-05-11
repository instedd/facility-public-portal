require "open3"
require "fileutils"

class DatasetsController < ApplicationController
  before_action :authenticate_user!
  before_action { @js_flags["menuItem"] = :datasets }
  layout "content"

  def import
    run_process("#{Rails.root}/bin/import-dataset #{Rails.root.join(Settings.input_dir).to_s}")
  end

  def import_ona
    run_process("#{Rails.root}/bin/end-to-end-import #{Rails.root.join(Settings.input_dir).to_s}")
  end

  def upload
    # TODO: Refactor `if/else` mess
    uploaded_io = params["file"]
    url = params["url"]
    name = params["name"]

    # TODO: Add parsing Sheet logic
    if url && name
      sheetId = url.match /^.*\/d\/(.*)\/.*$/
      if !sheetId
        render :json => {:error => "SheetId Not Found"}.to_json, :status => 404
      else
        render json: :ok
      end
    else
      if uploaded_io 
        filename_to_upload = uploaded_io.original_filename
        # TODO: Don't hardcode drive_enabled = `false `
        file_to_upload = {name: filename_to_upload, drive_enabled: false}

        FileUtils.mkdir_p DatasetsChannel.directory_for(file_to_upload)

        File.open(DatasetsChannel.path_for(file_to_upload), 'wb') do |file|
          file.write(uploaded_io.read)
        end

        DatasetsChannel.dataset_update
      end
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

  def run_process(cmd)
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
end
