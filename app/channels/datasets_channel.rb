class DatasetsChannel < ActionCable::Channel::Base
  def subscribed
    transmit(type: :datasets_update, datasets: DatasetsChannel.datasets)
    stream_for "events"
  end

  def self.import_log(pid, log)
    broadcast_to("events", type: :import_log, pid: pid, log: log)
  end

  def self.import_complete(pid, exit_code)
    broadcast_to("events", type: :import_complete, pid: pid, exit_code: exit_code)
  end

  def self.dataset_update
    broadcast_to("events", type: :datasets_update, datasets: datasets)
  end


  private

  FILES = %w(
    categories.csv
    category_groups.csv
    facilities.csv
    facility_categories.csv
    facility_types.csv
    locations.csv
  )

  def self.datasets
    FILES.each_with_object({}) { |file, datasets|
      datasets[file] = file_state(file)
    }
  end

  def self.file_state(name)
    path = File.join Rails.root, "data/input", name
    return nil unless File.exists?(path)
    stat = File.stat path

    {
      updated_at: stat.mtime,
      size: stat.size,
      md5: Digest::MD5.file(path).hexdigest,
      applied: false
    }
  end
end
