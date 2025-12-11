Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # Authentication routes
      post "auth/signup", to: "auth#signup"
      post "auth/login", to: "auth#login"
      post "auth/logout", to: "auth#logout"
      get "auth/me", to: "auth#me"

      # Course routes (for instructors and browsing)
      resources :courses, only: [ :index, :show, :create, :update, :destroy ] do
        member do
          post :publish
          post :unpublish
        end
        # Enrollment routes (for students)
        post :enroll, to: "enrollments#enroll"
        delete :unenroll, to: "enrollments#unenroll"
        get :progress, to: "enrollments#progress"

        # Lesson routes
        resources :lessons, only: [ :index, :show, :create, :update, :destroy ] do
          member do
            post :complete
          end
        end
      end

      # Student enrollments
      get "enrollments", to: "enrollments#index"
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
