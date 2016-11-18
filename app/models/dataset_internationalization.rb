class DatasetInternationalization

  def initialize(i18n_path)
    @i18n_data = CSV.read(i18n_path, headers: true, header_converters: :symbol).map { |r| r.to_h }
  end

  def i18n_lookup(text, source_lang, dest_lang)
    if source_lang == dest_lang
      text
    else
      row = @i18n_data.find { |d| d[source_lang] == text }
      row.try { |row| row[dest_lang] } || "[missing #{dest_lang}: #{text}]"
    end
  end

  def write_output(filename, data, headers)
    full_filename = File.join(OUTPUT_PATH, filename)
    puts "Writing #{full_filename}"

    CSV.open(full_filename, "wb") do |csv|
      csv << csv_headers(headers)
      data.each do |f|
        csv << headers.flat_map { |h| csv_value(h, f) }
      end
    end
  end

  # if header has name:locale then name:loc1, name:loc2, ... name:locN is returned
  def csv_headers(headers)
    headers.flat_map { |h|
      name, locale = h.split ':'
      if locale.nil?
        name
      else
        Settings.locales.keys.map { |l| "name:#{l}" }
      end
    }
  end

  # if header has name:locale then name:loc1, name:loc2, ... name:locN values are returned using i18n for translation
  def csv_value(header, source_row)
    name, locale = header.split ':'
    raw_value = source_row[name.to_sym]
    if locale.nil?
      raw_value
    else
      Settings.locales.keys.map { |l| i18n_lookup(raw_value, locale.to_sym, l) }
    end
  end
end
