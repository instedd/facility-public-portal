require "open3"

class DatasetsController < ApplicationController
  http_basic_authenticate_with name: Settings.admin_user, password: Settings.admin_pass
  before_action { @js_flags["menuItem"] = :datasets }
  layout "content"

  def import
    stdin, stdout, stderr, wait_thr = Open3.popen3("#{Rails.root}/bin/import-dataset", "#{Rails.root}/data/input")
    Thread.new do
      loop do
        ready = IO.select([stdout, stderr]).first
        r = ready.each do |io|
          data = io.read_nonblock(1024, exception: false)
          next if data == :wait_readable
          break :eof unless data

          ImportChannel.broadcast_to(wait_thr.pid, log: data)
        end
        break if r == :eof
      end
      [stdin, stdout, stderr].each &:close
      puts wait_thr.value
    end
    render json: { process_id: wait_thr.pid.to_s }
  end
end
