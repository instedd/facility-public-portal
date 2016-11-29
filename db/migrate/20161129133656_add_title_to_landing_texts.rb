class AddTitleToLandingTexts < ActiveRecord::Migration[5.0]
  def up
    connection = ActiveRecord::Base.connection.raw_connection
    connection.prepare("add-title-st", "update landing_texts set texts = $1 where id = $2")

    execute("select id, texts from landing_texts").each do |t|
      texts = JSON.parse(t["texts"])
      texts["title"] = "Master Facility Registry"

      connection.exec_prepared('add-title-st', [texts.to_json, t["id"]])
    end
  end

  def down
    connection = ActiveRecord::Base.connection.raw_connection
    connection.prepare("drop-title-st", "update landing_texts set texts = $1 where id = $2")

    execute("select id, texts from landing_texts").each do |t|
      texts = JSON.parse(t["texts"])
      texts.delete("title")

      connection.exec_prepared('drop-title-st', [texts.to_json, t["id"]])
    end
  end
end
