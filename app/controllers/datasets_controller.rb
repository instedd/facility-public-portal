require "open3"

class DatasetsController < ApplicationController
  http_basic_authenticate_with name: Settings.admin_user, password: Settings.admin_pass
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
    File.open(Rails.root.join('data', 'input', uploaded_io.original_filename), 'wb') do |file|
      file.write(uploaded_io.read)
    end
    DatasetsChannel.dataset_update
    render json: :ok
  end
end
