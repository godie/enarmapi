Rails.application.routes.draw do
  # Nuevas rutas unificadas
  resources :users do
    collection do
      post "login"
      post "google_login"
      post "facebook_login"
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
      post "facebook_login", to: "users#facebook_login"
    end
    resources :achievements, only: [ :index ], controller: "users/achievements"
  end

  resources :categories do
    resources :clinical_cases, only: [ :index ]
  end
  resources :clinical_cases
  resources :questions
  resources :exams
  resources :achievements, only: [ :index, :create, :update, :destroy ]
  resources :user_exams, only: [ :index, :show, :create, :update ]

  get "flashcards/due", to: "flashcards#due"
  post "flashcards/:id/review", to: "flashcards#review"
  resources :flashcards, only: [ :index, :show ]

  resources :specialists, only: [ :index, :show ]
  resources :messages, only: [ :index, :show, :create ]

  # Respuestas (unificadas)
  post "player_answers", to: "user_answers#create" # Mantenemos el nombre de la ruta para el frontend
  get "player_answers", to: "user_answers#index"

  post "user_answers", to: "user_answers#create"
  get "user_answers", to: "user_answers#index"

  post "ai/generate_question", to: "ai#generate_question"
  post "ai/generate_clinical_case", to: "ai#generate_clinical_case"
  post "ai/bulk_create_exam", to: "ai#bulk_create_exam"

  get "leaderboard", to: "leaderboard#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
