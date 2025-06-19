Rails.application.routes.draw do
  resources :users
  resources :players
  post "auth_user", to: "auth#auth_user"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  resources :categories
  resources :clinical_cases do
    resources :questions
  end

  post 'player_answers', to: 'player_answers#create'
  get 'player_answers', to: 'player_answers#index'

  resources :exams

  # Defines the root path route ("/")
  # root "posts#index"
end
