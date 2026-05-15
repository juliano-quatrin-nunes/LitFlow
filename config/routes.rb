Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  
  get "register/:token", to: "registrations#new", as: :new_registration
  post "register/:token", to: "registrations#create", as: :registration

  namespace :admin do
    resources :invitations, only: [ :index, :create, :destroy ]
  end

  resources :saved_musics, only: [ :index, :create, :update, :destroy ]
  get "p/setlists/:uid", to: "setlists#public_show", as: :public_setlist
  resources :setlists
  resources :setlist_items, only: [ :new, :create, :update, :destroy ] do
    collection do
      patch :reorder
    end
  end

  namespace :repertoire do
    resources :authors, only: [ :index, :create ]
    resources :musics, only: [ :index, :new, :create ]

    scope "musics/:author_slug", as: :music_by_author do
      get ":id", to: "musics#show", as: :show
      get ":id/edit", to: "musics#edit", as: :edit
      patch ":id", to: "musics#update", as: :update
      put ":id", to: "musics#update"
      delete ":id", to: "musics#destroy", as: :destroy
      
      get ":id/liturgical_categories/edit", to: "musics/liturgical_categories#edit", as: :edit_liturgical_categories
      patch ":id/liturgical_categories", to: "musics/liturgical_categories#update", as: :liturgical_categories
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "repertoire/musics#index"
end
