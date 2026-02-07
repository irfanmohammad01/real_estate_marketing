Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # super user login
  post "/auth/super/login", to: "auth/super_users#login"

  # user agent login
  post "/auth/login", to: "auth/users#login"

  # org admin create & update
  namespace :admin do
    resources :org_admins, only: [ :create, :update ]
  end

  # Create organization with first user (super user only)
  # post "/organizations/create_with_user", to: "organizations#create_with_user"

  resources :organizations do
    post :restore, on: :member
  end

  resources :users, only: [ :create, :update, :index, :show ]


  resources :email_types, only: [ :create, :index ]
  get "/email_templates/by_type", to: "email_templates#by_type"
  resources :email_templates, only: [ :create, :index, :show, :update ]

  # Preferences
  resources :preferences, only: [ :index ]

  resources :contacts, only: [ :create, :index ] do
    collection do
      get :paginated
      post :import
    end
  end


  # Defines the root path route ("/")
  # root "posts#index"
end
