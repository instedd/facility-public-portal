class CreateLandingTexts < ActiveRecord::Migration[5.0]
  def up
    create_table :landing_texts do |t|
      t.boolean :draft, null: false, default: true
      t.string :locale, null: false
      t.jsonb :texts, null: false

      t.timestamps
    end
  end

  def down
    drop_table :landing_texts
  end
end
