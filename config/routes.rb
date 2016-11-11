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

  scope :content do
    get  '/edit', to: "landing_editor#index"
    get  ':edit_locale/edit', to: 'landing_editor#edit'
    post ':edit_locale/edit', to: 'landing_editor#save'
    get  ':edit_locale/preview', to: 'landing_editor#preview'
    post ':edit_locale/publish_draft', to: 'landing_editor#publish_draft'
    post ':edit_locale/discard_draft', to: 'landing_editor#discard_draft'
  end

  get '*unmatched_route', :to => 'application#map'
end
