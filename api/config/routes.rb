Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API Routes
  namespace :api do
    namespace :v1 do
      # Authentication
      post 'auth/register', to: 'auth#register'
      post 'auth/login', to: 'auth#login'
      get 'auth/me', to: 'auth#me'

      # Transactions
      resources :transactions do
        member do
          post :apply_rules
        end
        collection do
          post :bulk_categorize
          post :bulk_mark_reviewed
          delete :bulk_delete
          post :bulk_apply_rules
          post :bulk_detect_anomalies
          post :import_csv
        end
      end

      # Categories
      resources :categories do
        member do
          get :stats
        end
      end

      # Categorization Rules
      resources :categorization_rules do
        collection do
          post :bulk_activate
          post :bulk_deactivate
          delete :bulk_delete
          post :bulk_reorder
        end
      end

      # Anomalies
      resources :anomalies, only: [:index, :show] do
        member do
          patch :resolve
        end
        collection do
          post :bulk_resolve
          get :stats
        end
      end

      # CSV Imports
      resources :csv_imports, only: [:index, :show, :create, :destroy] do
        member do
          get :progress
        end
        collection do
          post :presigned_url
        end
      end

      # Dashboard
      get 'dashboard/summary', to: 'dashboard#summary'
      get 'dashboard/spending_trends', to: 'dashboard#spending_trends'
      get 'dashboard/recent_activity', to: 'dashboard#recent_activity'
      
      # Job Queue Monitoring
      get 'job_queue/status', to: 'job_queue#status'
      get 'job_queue/workers', to: 'job_queue#workers'
    end
  end

  # ActionCable WebSocket endpoint
  mount ActionCable.server => '/cable'

  # Defines the root path route ("/")
  # root "posts#index"
end
