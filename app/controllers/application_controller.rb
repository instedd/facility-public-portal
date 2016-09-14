class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def map
    @js_flags = {
      "initialPosition" => [8.979787, 38.758917],
      "fakeUserPosition" => Rails.env.development?
    }
  end
end
