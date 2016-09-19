Rails.application.routes.draw do
  root to: "application#map"

  scope :api do
    get 'suggest', to: 'api#suggest'
  end

  get '*unmatched_route', :to => 'application#map'
end
