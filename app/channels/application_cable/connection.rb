module ApplicationCable
  class Connection < ActionCable::Connection::Base
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include ActiveSupport::SecurityUtils

    def connect
      unless authenticate
        reject_unauthorized_connection
      end
    end

    private

    def authenticate
      authenticate_with_http_basic do |user, password|
        secure_compare(user, Settings.admin_user) & secure_compare(password, Settings.admin_pass)
      end
    end
  end
end
