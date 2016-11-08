class CreateLandingTexts < ActiveRecord::Migration[5.0]
  def up
    create_table :landing_texts do |t|
      t.boolean :preview, default: true
      t.jsonb :texts

      t.timestamps
    end

    LandingText.create preview: false, texts: {"heading"=>"Welcome to the Registry for all health facilities in the country",
      "subsection"=>"## The system provides\r\n\r\n- The possibility to search by province, facility name or necessary service\r\n- Advances search by name, services, ownership, type of facility, and location\r\n- Map view for assessing distance\r\n- GPS location of user to see what is closest to them\r\n- The entire facility list to download and use as data for other systems",
      "left_column"=>"## Location services\r\n\r\nPress the location button on the bottom right to see where you are right now",
      "right_column"=>"## Are you a dev?\r\n\r\nWe provide an API to help with any searches",
      "intro_to_search"=>"## Find the facility that fits your needs\r\n\r\nEvery facility in each county has a list of services to help find whatever is necessary. Contact details are provided to get in touch with professionals in a moment of need."
    }
    LandingText.create preview: true, texts: {"heading"=>"Welcome to the Registry for all health facilities in the country",
      "subsection"=>"## The system provides\r\n\r\n- The possibility to search by province, facility name or necessary service\r\n- Advances search by name, services, ownership, type of facility, and location\r\n- Map view for assessing distance\r\n- GPS location of user to see what is closest to them\r\n- The entire facility list to download and use as data for other systems",
      "left_column"=>"## Location services\r\n\r\nPress the location button on the bottom right to see where you are right now",
      "right_column"=>"## Are you a dev?\r\n\r\nWe provide an API to help with any searches",
      "intro_to_search"=>"## Find the facility that fits your needs\r\n\r\nEvery facility in each county has a list of services to help find whatever is necessary. Contact details are provided to get in touch with professionals in a moment of need."
    }
  end

  def down
    drop_table :landing_texts
  end
end
