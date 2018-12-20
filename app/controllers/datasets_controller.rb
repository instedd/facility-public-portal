require "open3"
require "fileutils"

class DatasetsController < ApplicationController
  before_action :authenticate_user!
  before_action { @js_flags["menuItem"] = :datasets }
  layout "content"

  def import
    stdin, stdout, stderr, wait_thr = Open3.popen3("#{Rails.root}/bin/import-dataset", "#{Rails.root}/data/input")
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

  def upload
    uploaded_io = params["file"]
    filename_to_upload = uploaded_io.original_filename

    FileUtils.mkdir_p DatasetsChannel.directory_for(filename_to_upload)

    File.open(DatasetsChannel.path_for(filename_to_upload), 'wb') do |file|
      file.write(uploaded_io.read)
    end

    DatasetsChannel.dataset_update
    render json: :ok
  end

  def download
    requested_file = "#{params[:filename]}.csv"

    # Set MIME type to */* to avoid browsers complaining with
    # "Resource interpreted as Document but transferred with MIME type text/csv"
    send_file(DatasetsChannel.path_for(requested_file), filename: requested_file, type: '*/*')
  end
end
