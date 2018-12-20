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

  def self.directory_for(filename)
    if ONA_FILES.include?(filename)
      Rails.root.join(Settings.input_dir, 'ona')
    elsif (FILES + RAW_FILES).include?(filename)
      Rails.root.join(Settings.input_dir)
    else
      raise ArgumentError.new("Unknown filename")
    end
  end

  def self.path_for(filename)
    Rails.root.join(directory_for(filename), filename)
  end

  private

  FILES = %w(
    categories.csv
    category_groups.csv
    facility_types.csv
    locations.csv
  )

  RAW_FILES = %w(
    facilities.csv
    facility_categories.csv
  )

  ONA_FILES = %w(
    data.csv
    mapping.csv
  )

  def self.files_to_hash(files)
    files.each_with_object({}) { |file, datasets|
      datasets[file] = file_state(path_for(file))
    }
  end

  def self.datasets
    ona_files = files_to_hash(FILES + ONA_FILES)
    raw_files = files_to_hash(FILES + RAW_FILES)

    {
      ona: ona_files,
      raw: raw_files,
    }
  end

  def self.file_state(path)
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
