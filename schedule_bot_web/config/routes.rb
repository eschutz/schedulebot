Rails.application.routes.draw do
  get '/getting-started', to: 'information#getting_started'

  root :to => 'information#index'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
