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
  
  resources :posts
  root to: "home#index"

end
