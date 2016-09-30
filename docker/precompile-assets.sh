#!/bin/bash
set -euo pipefail


if ! [[ -v SKIP_ASSETS_COMPILATION ]]; then
    bundle exec rake assets:precompile RAILS_ENV=production SECRET_KEY_BASE=secret
fi
