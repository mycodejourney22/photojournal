Rails.application.routes.draw do
  get 'prices/new'
  get 'prices/index'
  get 'prices/create'
  get 'prices/update'
  get 'prices/post'
  get 'gadgets/index'
  get 'gadgets/new'
  get 'gadgets/show'
  get 'galleries/new'
  get 'galleries/show'
  get 'galleries/index'
  get 'galleries/create'
  get 'expenses/new'
  get 'expenses/create'
  get 'expenses/index'
  get 'sales/index'
  get 'sales/new'
  get 'sales/create'
  get 'sales/show'
  get '/welcome', to: 'pages#public_home', as: :public_home

  resources :operations, only: [:index] do
    get 'daily_sales/:date', to: 'operations#daily_sales', as: :daily_sales, on: :collection
  end

  post 'webhooks/paystack', to: 'paystackwebhooks#paystack'
  get 'make_payment', to: 'payments#make_payment'
  post 'paystack_payment', to: 'payments#initiate_payment'
  resources :payments, only: [] do
    collection do
      get :verify_payment
      get :success
      get :failure
    end
  end


  get 'photo_shoots/consent'
  resources :customers do
    member do
      get :all_galleries
      post :generate_referral
    end
  end

  resources :expenses , only: [:index, :create, :new]

  post '/webhooks/calendly', to: 'webhooks#calendly'

  # devise_for :users, controllers: {
  #   sessions: 'users/sessions'
  # }

  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }
  namespace :admin do
    resources :users, only: [:index, :edit, :update, :new, :create]
  end

  get 'password_setup/:token', to: 'password_setups#edit', as: :password_setup
  patch 'password_setup/:token', to: 'password_setups#update'
  # devise_scope :user do
  #   match '/sign-in' => "devise/sessions#new", :as => :login
  # end

  # devise_scope :user do
  #   delete 'sign_out'
  # end
  # mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  # mount Blazer::Engine, at: "blazer"
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
    collection do
      get :upcoming
      get :type_of_shoots
      post :select_price
      get :select_price
      get :past
      get :new_customer
      get :available_slots
      post :selected_date
      get :available_hours
      get :booking
      get :thank_you
    end

    member do
      patch :mark_no_show
      get :available_hours
      get :new_customer
      get :cancel_booking
      patch :cancel
      get :customer_pictures
      get :photo_inspirations

    end
    resources :photo_shoots, except: [:index, :destroy]
    resources :galleries, only: [:new, :create, :show, :update, :edit]
    resources :sales, only: [:index, :new, :create]
  end
  # get 'appointments/completed'
  get 'appointments/past'

  resources :referrals, only: [:index]
  get 'refer/:code', to: 'referrals#show', as: :referral
  get 'refer/:code/apply', to: 'referrals#apply', as: :apply_referral

  # Process pending rewards (admin only)
  post 'referrals/process_rewards', to: 'referrals#process_rewards', as: :process_referral_rewards

  resources :prices
  resources :photo_shoots, only: [:index] do
    collection do
      get :notes
    end
  end
  resources :galleries, only: [:index] do
    member do
      get 'download/:id', to: 'galleries#download', as: 'download'
      get 'stream_photo/:photo_id', to: 'galleries#stream_photo', as: :stream_photo
    end
  end
  post 'appointments/:appointment_id/galleries/:gallery_id', to: 'galleries#send_gallery', as: 'send_gallery'
  get 'galleries/public/:share_token', to: 'galleries#public_show', as: 'gallery_public'
  resources :gadgets

end
