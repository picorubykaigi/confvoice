Rails.application.routes.draw do
  resource :session, only: [ :new, :create, :destroy ]
  resource :registration, only: [ :new, :create ]

  namespace :admin do
    resources :users
  end

  resources :conferences, param: :slug do
    get "dashboard", to: "dashboards#show"
    get "qrcodes", to: "qrcodes#index"
    get "export", to: "exports#show", defaults: { format: :csv }

    namespace :manage do
      resources :memberships, only: [ :index, :create, :update, :destroy ]
      resources :sessions do
        resource :speaker_invite, only: [ :create, :destroy ]
      end
    end

    resources :sessions, only: [ :index, :show ] do
      resources :feedbacks, only: [ :index ] do
        resource :speaker_visibility, only: [ :update, :destroy ], controller: "feedback_speaker_visibilities"
      end
    end
  end

  get "speaker/:token", to: "speaker_portals#show", as: :speaker_portal

  get "up" => "rails/health#show", as: :rails_health_check

  root "pages#home"

  get ":slug", to: "public_conferences#show", as: :public_conference
  get "t/:id", to: "public_feedbacks#new", as: :public_feedback, constraints: { id: /\d+/ }
  post "t/:id", to: "public_feedbacks#create", constraints: { id: /\d+/ }
  post "t/:id/reactions", to: "public_reactions#create", as: :public_reactions, constraints: { id: /\d+/ }
  get "t/:id/thanks", to: "public_feedbacks#thanks", as: :public_feedback_thanks, constraints: { id: /\d+/ }
end
