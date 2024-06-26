Rails.application.routes.draw do
  get 'sales/index'
  get 'sales/new'
  get 'sales/create'
  get 'sales/show'
  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  mount Blazer::Engine, at: "blazer"
  root to: "appointments#index"
  resources :sales do
    collection do
      get :upfront
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get 'reports/dashboard', to: 'reports#dashboard'
  get 'reports/sales', to: 'reports#sales'

  # Defines the root path route ("/")
  # root "posts#index"
  resources :appointments do
    member do
      patch :mark_no_show
    end
    resources :photo_shoots, except: [:index, :destroy]
  end
  resources :photo_shoots, only: [:index] do
    collection do
      get :notes
    end
  end
end
