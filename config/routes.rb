Rails.application.routes.draw do
  # Users
  post 'users', to: 'users#create'
  put 'users/:id', to: 'users#update'
  get 'users/profile_photo/:id', to: 'users#get_profile_photo'
  put 'users/profile_photo/:id', to: 'users#set_profile_photo'

  # Orders
  get '/orders/available', to: 'orders#available_orders'
  put '/orders/associate/:id/:professional_id', to: 'orders#associate_professional'
  get '/orders/user/:user_id/active', to: 'orders#user_active_orders'
  get '/orders/active_orders_professional/:user_id', to: 'orders#associated_active_orders'
  get '/orders', to: 'orders#index'
  post '/orders', to: 'orders#create'
  get '/orders/:id', to: 'orders#show'
  put '/orders/:id', to: 'orders#update'
  delete '/orders/:id', to: 'orders#destroy'

  # Adresses
  get '/addresses/user/:user_id', to: 'addresses#get_by_user'
  post '/addresses', to: 'addresses#create'
  put '/addresses/:id', to: 'addresses#update'
  delete '/addresses/:id', to: 'addresses#destroy'
  
  resources :categories
  mount_devise_token_auth_for 'User', at: 'auth'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
