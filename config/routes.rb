Rails.application.routes.draw do
  root to: "application#landing"

  scope :api do
    get 'search', to: 'api#search'
    get 'suggest', to: 'api#suggest'
    get 'facilities/:id', to: 'api#get_facility'
    get 'facility_types', to: 'api#facility_types'
    get 'locations', to: 'api#locations'
    get 'services', to: 'api#services'
  end

  post 'facilities/:id/report', to: 'application#report_facility'
  get 'data', to: 'application#download_dataset'
  get 'map', to: 'application#map'
  get 'docs', to: 'docs#index'

  get 'edit', to: 'landing_editor#index'
  get 'preview', to: 'landing_editor#preview'
  post 'edit', to: 'landing_editor#edit'
  post 'discard_draft', to: 'landing_editor#discard_draft'

  get '*unmatched_route', :to => 'application#map'
end
