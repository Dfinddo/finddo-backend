Rails.application.routes.draw do
  # A rota / nesta api não tem utilidade
  root to: proc { [404, {}, ["Not found."]] }

  # Users
  post 'users', to: 'users#create'
  get 'users', to: 'users#get_user'
  put 'users/activate', to: 'users#activate_user'
  put 'users/:id', to: 'users#update'
  get 'users/profile_photo/:id', to: 'users#get_profile_photo'
  put 'users/profile_photo/:id', to: 'users#set_profile_photo'
  put 'users/player_id_notifications/:id', to: 'users#update_player_id'
  delete 'users/remove_player_id_notifications/:id/:player_id', to: 'users#remove_player_id'
  post 'users/get_token_wirecard', to: 'users#generate_access_token_professional'

  # Orders
  post '/orders/payment_webhook', to: 'orders#payment_webhook'
  get '/orders/available', to: 'orders#available_orders'
  put '/orders/associate/:id/:professional_id', to: 'orders#associate_professional'
  get '/orders/user/:user_id/active', to: 'orders#user_active_orders'
  get '/orders/active_orders_professional/:user_id', to: 'orders#associated_active_orders'
  post '/orders', to: 'orders#create'
  get '/orders/:id', to: 'orders#show'
  put '/orders/:id', to: 'orders#update'
  patch '/orders/:id', to: 'orders#update'
  delete '/orders/:id', to: 'orders#destroy'

  # Adresses
  get '/addresses/user/:user_id', to: 'addresses#get_by_user'
  post '/addresses', to: 'addresses#create'
  put '/addresses/:id', to: 'addresses#update'
  delete '/addresses/:id', to: 'addresses#destroy'
  
  # As categorias no momento não são cadastradas por interface de adm, apenas pelo
  # seeds.rb
  # resources :categories
  mount_devise_token_auth_for 'User', at: 'auth'
end
