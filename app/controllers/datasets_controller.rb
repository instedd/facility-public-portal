class DatasetsController < ApplicationController
  http_basic_authenticate_with name: Settings.admin_user, password: Settings.admin_pass
  before_action { @js_flags["menuItem"] = :datasets }
  layout "content"
end
