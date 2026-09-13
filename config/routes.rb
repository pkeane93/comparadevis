Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Everything happens on the landing page: uploads on top, comparison
  # underneath. `show` is not a page — it serves the comparison panel that
  # the page polls while the job runs.
  #
  # The locale is an optional URL segment (/, /fr, /nl all work) so links are
  # shareable per language instead of depending on a session.
  scope "(:locale)", locale: /en|fr|nl/ do
    root "comparisons#new"
    resources :comparisons, only: [ :create, :show ]
  end
end
