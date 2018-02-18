Rails.application.routes.draw do

  # This line mounts Spree's routes at the root of your application.
  # This means, any requests to URLs such as /products, will go to Spree::ProductsController.
  # If you would like to change where this engine is mounted, simply change the :at option to something different.
  #
  # We ask that you don't use the :as option here, as Spree relies on it being the default of "spree"
  # get '/store_ref' => 'client#store_ref',  as: :client_store_ref
  

  mount Spree::Core::Engine, at: '/'

  Spree::Core::Engine.routes.draw do
    get '/store_ref_in',  :to => "client_site#store_ref_in",  :as => 'client_store_ref_in'
    get '/store_ref_out', :to => "client_site#store_ref_out", :as => 'client_store_ref_out'
  end

          # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
