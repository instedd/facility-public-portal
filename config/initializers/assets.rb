# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.

elm_src_path = Rails.root.join("app", "assets", "elm")

elm_entry_points = elm_src_path.children
                               .select { |entry| entry.file? && entry.basename.to_s =~ /Main.*\.elm/ }
                               .map    { |entry| entry.basename.to_s.gsub(/elm$/, "js") }

Rails.application.config.assets.paths << elm_src_path
Rails.application.config.assets.precompile += elm_entry_points
