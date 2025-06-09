Rails.application.routes.draw do
  get "home/index"
  # devise_for :users, controllers: { registrations: 'api/users/registrations' }
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }


  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  resources :users, only: [:index, :show, :edit, :update, :destroy] 

  resources :calendar, only: [:index] do
    collection do
      get :create_event_form
      post :create_event
      get :event
      get :edit_event_form
      post :update_event
      post :delete_event
    end
  end

  get 'calendar/all_events', to: 'calendar#all_events', as: :all_events
  get 'calendar/all_holidays', to: 'calendar#all_holidays', as: :all_holidays

  # google sheets
  get '/sheets', to: 'sheets#index'


  # big query
  get '/bigquery', to: 'bigquery#index'
  get 'bigquery/table/:project_id/:dataset_id', to: 'bigquery#tables_index', as: 'bigquery_table'
  get 'bigquery/datasets/:project_id/:dataset_id/tables/:table_id', to: 'bigquery#show_table', as: 'bigquery_table_detail'
  get 'bigquery/datasets/schema/:project_id/:dataset_id/tables/:table_id', to: 'bigquery#show_schema', as: 'bigquery_table_schema'
  get 'bigquery/datasets/schema/edit/:project_id/:dataset_id/tables/:table_id', to: 'bigquery#edit_schema_form', as: 'bigquery_table_schema_edit_form'
  get 'bigquery/create_table/:project_id/:dataset_id', to: 'bigquery#new_create_table', as: 'new_bigquery_create_table'
  post 'bigquery/create_table/:project_id/:dataset_id', to: 'bigquery#create_table', as: 'bigquery_create_table'
  get 'bigquery/upload_table/:project_id/:dataset_id', to: 'bigquery#upload_table_form', as: 'bigquery_upload_table_form'
  post 'bigquery/upload_table/:project_id/:dataset_id', to: 'bigquery#upload_table', as: 'bigquery_upload_table'

  # api only # to delete
  post 'bigquery/create_tables/:project_id/:dataset_id', to: 'bigquery#create_tables'

  resources :posts
  root to: "home#index"


  # api
  namespace :api do
    namespace :v1 do
      post 'auth/google', to: 'auth#google'
      get 'bigquery/datasets', to: 'bigquery#index'
      get 'bigquery/tables/:project_id/:dataset_id', to: 'bigquery#table_list'
    
      get 'bigquery/tables/:dataset_id/:table_id', to: 'bigquery#show_table'
    end
  end

end
