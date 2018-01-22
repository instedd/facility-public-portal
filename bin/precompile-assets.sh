#!/bin/bash
set -euo pipefail

# Define locales that should be available on js assets
# for safety, all locales in ./config/locales/*.yml
RAILS_ENV=production \
  SETTINGS__LOCALES__EN=English \
  SETTINGS__LOCALES__ES=Español \
  SETTINGS__LOCALES__AM=አማርኛ \
  bundle exec rake i18n:js:export

bundle exec rake assets:precompile RAILS_ENV=production SECRET_KEY_BASE=secret

echo "done"
