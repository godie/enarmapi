Rails.application.routes.draw do
  # Nuevas rutas unificadas
  resources :users do
    collection do
      post "login"
      post "google_login"
      get "me/stats", to: "users#stats"
      get "me/contributions", to: "users#contributions"
    end
    resources :achievements, only: [ :index ], controller: "users/achievements"
  end

  # Rutas de legacy para el frontend (apuntan a UsersController)
  resources :players, controller: "users" do
    collection do
      post "login", to: "users#login"
      post "google_login", to: "users#google_login"
    end
    resources :achievements, only: [ :index ], controller: "users/achievements"
  end

  resources :categories do
    resources :clinical_cases, only: [ :index ]
  end
  resources :clinical_cases
  resources :questions
  resources :exams
  resources :user_exams, only: [ :index, :show, :create, :update ]
  resources :achievements, only: [ :index, :create, :update, :destroy ]

  # Respuestas (unificadas)
  post "player_answers", to: "user_answers#create" # Mantenemos el nombre de la ruta para el frontend
  get "player_answers", to: "user_answers#index"

  post "user_answers", to: "user_answers#create"
  get "user_answers", to: "user_answers#index"

  post "ai/generate_question", to: "ai#generate_question"
  post "ai/generate_clinical_case", to: "ai#generate_clinical_case"

  get "leaderboard", to: "leaderboard#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
