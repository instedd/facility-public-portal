require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FPP
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.middleware.use Rack::Deflater
    config.middleware.insert_before ActionDispatch::Static, ActionDispatch::Static, "#{Rails.root}/public_override"

    config.i18n.default_locale = Settings.default_locale.to_sym
    config.i18n.available_locales = Settings.locales.keys
  end
end
