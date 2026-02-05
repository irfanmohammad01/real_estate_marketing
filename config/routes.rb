Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # super user login
  post "/auth/super/login", to: "auth/super_users#login"

  # user agent login
  post "/auth/login", to: "auth/users#login"

  # org admin create
  post "/admin/org_admins", to: "admin/org_admins#create"
  # org admin update
  patch "/admin/org_admins/:id", to: "admin/org_admins#update"

  resources :organizations do
    post :restore, on: :member
  end

  resources :users, only: [ :create, :update, :index ]


  # Defines the root path route ("/")
  # root "posts#index"
end
