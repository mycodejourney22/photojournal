require 'sidekiq/web'
require 'sidekiq-scheduler/web'

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

  get 'smugmug_dashboard', to: 'smugmug_dashboard#index'
  post 'smugmug_dashboard/retry_upload/:id', to: 'smugmug_dashboard#retry_upload', as: 'retry_upload_smugmug_dashboard'
  post 'smugmug_dashboard/refresh_token/:id', to: 'smugmug_dashboard#refresh_token', as: 'refresh_token_smugmug_dashboard'


  resources :operations, only: [:index] do
    get 'daily_sales/:date', to: 'operations#daily_sales', as: :daily_sales, on: :collection
  end

  namespace :api do
    namespace :v1 do
      resources :prices, only: [:index, :show]
      resources :available_slots, only: [:index]

      resources :appointments, only: [:create, :show] do
        member do
          post :cancel
        end
      end

      resources :referrals, only: [] do
        collection do
          get :validate
        end
      end

      resources :credits, only: [] do
        collection do
          get :check
        end
      end

      resources :payments, only: [] do
        collection do
          post :initiate
          get :verify
        end
      end
    end
  end

  post '/webhooks/paystack', to: 'paystack_webhooks#paystack'
  get 'make_payment', to: 'payments#make_payment'
  post 'paystack_payment', to: 'payments#initiate_payment'
  resources :payments, only: [] do
    collection do
      get :verify_payment
      get :success
      get :failure
    end
  end

  authenticate :user, lambda { |u| u.admin? || u.super_admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  resources :appointment_reports, only: [:index]

  get 'photo_shoots/consent'
  resources :customers do
    member do
      get :all_galleries
      post :generate_referral
    end

    collection do
      get 'export'
      post 'sync_all_to_brevo'
    end
  end

  resources :customers_analytics, only: [:index]

  # For detailed analytics, you might want to add these specific routes too:
  get 'customers_analytics/top_spenders', to: 'customers_analytics#top_spenders'
  get 'customers_analytics/frequent_visitors', to: 'customers_analytics#frequent_visitors'
  get 'customers_analytics/export', to: 'customers_analytics#export'

  resources :expenses , only: [:index, :create, :new]

  post '/webhooks/calendly', to: 'webhooks#calendly'

  # devise_for :users, controllers: {
  #   sessions: 'users/sessions'
  # }

  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }

  resources :attendance_records do
    collection do
      get 'upload'
      post 'import'
      get 'report'
    end
  end

  namespace :admin do
    resources :users, only: [:index, :edit, :update, :new, :create] do
      member do
        patch :toggle_active
      end
    end

    resources :coupons do
      member do
        patch :toggle_status
      end
    end
    
    resources :special_emails, only: [:index, :new, :create] do
      collection do
        get :mothers_day
        get :eid_celebration
        get :christmas
        get :new_year
        post :send_special_email
      end
    end

    resources :setup, only: [:index]
    
    resources :prices do
      member do
        patch :toggle_active
      end
    end
    
    resources :staff_members, controller: 'staff' do
      member do
        patch :toggle_active
      end
    end
    
    resources :studios do
      member do
        patch :toggle_active
      end
    end
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
  get 'galleries/:id/stream_photo/:photo_id', to: 'galleries#stream_photo', as: 'stream_photo_gallery'

  resources :appointments do
    collection do
      get :upcoming
      get :type_of_shoots
      post :select_price
      get :select_price
      get :in_progress
      get :past
      get :new_customer
      get :available_slots
      post :selected_date
      get :available_hours
      get :booking
      get :thank_you
      delete :cancel

    end

    member do
      post :add_note
      delete :remove_note
      patch :toggle_note_action
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
    resources :refund_requests, only: [:new, :create]
    resources :galleries, only: [:new, :create, :show, :update, :edit] do
      member do
        post 'upload_to_smugmug'
        get 'stream_photo/:photo_id', to: 'galleries#stream_photo', as: 'stream_photo'
        get 'add_to_existing', action: :add_to_existing, as: :add_to_existing
        post 'upload_to_existing', action: :upload_to_existing, as: :upload_to_existing
      end

      collection do
        get 'public/:share_token', to: 'galleries#public_show', as: 'public'
        get 'smugmug/:id', to: 'galleries#smugmug_redirect', as: 'smugmug'


      end
    end
    resources :sales, only: [:index, :new, :create]
  end
  # get 'appointments/completed'
  get 'appointments/past'

  resources :referrals, only: [:index]
  get 'refer/:code', to: 'referrals#show', as: :referral
  get 'refer/:code/apply', to: 'referrals#apply', as: :apply_referral

  get 'refund/:appointment_uuid/request', to: 'refund_requests#new', as: 'appointment_refund_request_public'

  resources :refund_requests, only: [:index, :show] do
    member do
      patch :approve
      patch :decline
      patch :process_refund
    end

    collection do
      get :confirmation
    end
  end

  # Routes for bulk mapping
  resources :smugmug_admin, only: [:index] do
    collection do
      get :search_appointments
      get :search_smugmug
    end

    member do
      get :map_gallery
      post :create_mapping
    end
  end

  resources :staff_reports, only: [:index] do
    collection do
      get :photographer_detail
      get :editor_detail
    end
  end


  # Process pending rewards (admin only)
  post 'referrals/process_rewards', to: 'referrals#process_rewards', as: :process_referral_rewards

  resources :prices
  resources :photo_shoots, only: [:index] do
    collection do
      get :notes
    end
  end
  # resources :galleries, only: [:index] do
  #   member do
  #     get 'download/:id', to: 'galleries#download', as: 'download'
  #     get 'stream_photo/:photo_id', to: 'galleries#stream_photo', as: :stream_photo
  #   end
  # end

  # This route is for the download handler
  get 'galleries/download/:id', to: 'galleries#download', as: 'download_gallery'

  # Customer gallery access
  resources :customer_galleries, only: [:index, :show] do

    member do
      get 'download/:photo_id', action: :download_photo, as: :download_photo
    end

    collection do
      get :access
      post :authenticate
      get :verify
      post :process_verification
      get :logout
    end
  end

  # For direct access to public gallery URLs
  get 'gallery/:share_token', to: 'galleries#public_show', as: :gallery_public

  # This route is for sending gallery links to customers
  post 'appointments/:appointment_id/galleries/:gallery_id/send', to: 'galleries#send_gallery', as: 'send_gallery'
  # post 'appointments/:appointment_id/galleries/:gallery_id', to: 'galleries#send_gallery', as: 'send_gallery'
  # get 'galleries/public/:share_token', to: 'galleries#public_show', as: 'gallery_public'
  resources :gadgets

end
