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
  get "p/setlists/:uid/cifra_pdf", to: "setlists/cifra_pdf#show", as: :public_setlist_cifra_pdf
  get "p/setlists/:uid/cifra_docx", to: "setlists/cifra_docx#show", as: :public_setlist_cifra_docx
  get "p/setlists/:uid/pptx", to: "setlists/pptx#show", as: :public_setlist_pptx
  resources :setlists do
    get "pptx", to: "setlists/pptx#show", as: :pptx
    get "cifra_pdf", to: "setlists/cifra_pdf#show", as: :cifra_pdf
    get "cifra_docx", to: "setlists/cifra_docx#show", as: :cifra_docx
  end
  resources :setlist_items, only: [ :new, :create, :edit, :update, :destroy ] do
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

    scope "musics/:author_slug/:id", as: :music do
      post "slide_deck", to: "musics/slide_decks#create", as: :slide_deck
      patch "slide_deck", to: "musics/slide_decks#update"
      post "slide_deck/regenerate", to: "musics/slide_decks#regenerate", as: :regenerate_slide_deck
      get "pptx", to: "musics/pptx#show", as: :pptx
      get "cifra_pdf", to: "musics/cifra_pdf#show", as: :cifra_pdf
      get "cifra_docx", to: "musics/cifra_docx#show", as: :cifra_docx
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
