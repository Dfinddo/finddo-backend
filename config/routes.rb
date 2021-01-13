Rails.application.routes.draw do
  # A rota / nesta api não tem utilidade
  root to: proc { [403, {}, ["Forbidden"]] }
  
  require 'sidekiq/web'
  require 'sidekiq-scheduler/web'
  mount Sidekiq::Web => '/sidekiq'
  
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
  post 'orders/budget_approve', to: 'orders#budget_approve'
  post '/orders/propose_budget', to: 'orders#propose_budget'
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
  mount_devise_token_auth_for 'User', at: 'auth', controllers: {
    sessions:  'sessions'
  }

  namespace :api do
    namespace :v2 do
      mount_devise_token_auth_for 'User', at: 'auth'

      post '/login', to: 'auth#login'
      get '/auto_login', to: 'auth#auto_login'

      # Users
      post 'users', to: 'users#create'
      get 'users', to: 'users#get_user'
      put 'users/activate', to: 'users#activate_user'
      post 'users/add_credit_card', to: 'users#add_credit_card'
      get 'users/get_credit_card', to: 'users#get_customer_credit_card_data'
      delete 'users/credit_card/:card_id', to: 'users#remove_customer_credit_card_data'
      put 'users/:id', to: 'users#update'
      get 'users/profile_photo/:id', to: 'users#get_profile_photo'
      put 'users/profile_photo/:id', to: 'users#set_profile_photo'
      put 'users/player_id_notifications/:id', to: 'users#update_player_id'
      delete 'users/remove_player_id_notifications/:id/:player_id', to: 'users#remove_player_id'
      post 'users/get_token_wirecard', to: 'users#generate_access_token_professional'
      post 'users/find_by_name', to: 'users#find_professional_by_name'
      get 'users/set_player_id', to: 'users#set_player_id'

      # Orders
      get 'orders/em_servico/:id', to: 'orders#change_to_em_servico'
      put '/orders/disassociate/:id', to: 'orders#disassociate_professional'
      put 'orders/cancel/:id', to: 'orders#cancel_order'
      post 'orders/budget_approve', to: 'orders#budget_approve'
      post '/orders/propose_budget', to: 'orders#propose_budget'
      post '/orders/payment_webhook', to: 'orders#payment_webhook'
      post '/orders/create_order_wirecard/:id', to: 'orders#create_order_wirecard'
      post '/orders/create_payment/:id', to: 'orders#create_payment'
      get '/orders/available', to: 'orders#available_orders'
      put '/orders/associate/:id/:professional_id', to: 'orders#associate_professional'
      get '/orders/user/active', to: 'orders#user_active_orders'
      get '/orders/active_orders_professional/', to: 'orders#associated_active_orders'
      post '/orders', to: 'orders#create'
      put '/orders/problem_solved', to: 'orders#problem_solved'
      get '/orders/:id', to: 'orders#show'
      put '/orders/:id', to: 'orders#update'
      delete '/orders/:id', to: 'orders#destroy'
      post 'orders/:id/reschedulings', to: 'orders#create_rescheduling'
      put 'orders/:id/reschedulings/:accepted', to: 'orders#update_rescheduling'
      put 'orders/direct_associate_professional/:id/:professional_id', to: 'orders#direct_associate_professional'
      get 'expired', to:  'orders#expired_orders'
      put '/orders/rate/:id', to: 'orders#order_rate'
      get 'request_cancelation_of_order/:id', to: 'orders#request_cancelation'
    
      # Adresses
      get '/addresses/user/:user_id', to: 'addresses#get_by_user'
      post '/addresses', to: 'addresses#create'
      put '/addresses/:id', to: 'addresses#update'
      delete '/addresses/:id', to: 'addresses#destroy'
      
      # Chats
      get '/chats', to: 'chats#index'
      get '/chats/order/', to: 'chats#get_by_order'
      get 'chats/list', to: 'chats#get_chat_list'
      get '/chats/order/admin', to: 'chats#admin_chat_from_order'
      get '/chats/list/admin', to: 'chats#get_chat_with_admin_list'
      get '/chats', to: 'chats#show'
      get '/chats/user/admin', to: 'chats#get_chat_with_admin'
      get '/chats/admin/all', to: 'chats#for_admin_get_chat_list'
      post '/chats', to: 'chats#create'
      post '/chats/admin', to: 'chats#create_chat_admin'

      # Notifications
      post 'notification', to: 'notification#send_notification_with_user_id'

    end
  end
end
