module ApplicationCable
  class Connection < ActionCable::Connection::Base
    include Devise::Controllers::Helpers

    def connect
      unless user_signed_in?
        reject_unauthorized_connection
      end
    end
  end
end
