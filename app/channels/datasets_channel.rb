class DatasetsChannel < ActionCable::Channel::Base
  def subscribed
    transmit(datasets)
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

  def datasets
    FILES.each_with_object({}) { |file, datasets|
      datasets[file] = file_state(file)
    }
  end

  def file_state(name)
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
