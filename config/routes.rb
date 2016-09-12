Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root to: "application#map"

  scope :api do
    get 'suggest', to: 'api#suggest'
  end
end
