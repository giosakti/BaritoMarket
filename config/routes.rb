Rails.application.routes.draw do
  devise_for :users, skip: :all

  resources :services
  resources :forwarders
  resources :service_configs
  resources :stores
  resources :groups

  devise_scope :user do
    get "home/index", to: 'devise/cas_sessions#new', as: :new_user_session
    get "users/sign_out", to: 'devise/cas_sessions#destroy', as: :destroy_user_session
    get "users/service", to: 'devise/cas_sessions#service', as: :user_service
  end

  root :controller => :home, :action => :index

  resources :home, :only => [:index]

  namespace :admin do
    resources :index, :only => [:index]
  end
end