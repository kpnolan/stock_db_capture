ActionController::Routing::Routes.draw do |map|
  map.resources :splits

  map.resources :sim_positions

  map.resources :orders

  map.resources :trigger_strategies

  map.resources :exit_strategies

  map.resources :entry_strategies

  map.resources :position_series

  map.resources :tda_positions, :member => { :close => :put, :plot => :get }, :collection => { :open => :post, :summary => :get }
  map.resources :snapshots
  map.resources :studies
  map.resources :indicators
  map.resources :intra_snapshots
  map.resources :industries
  map.resources :sectors
  map.resources :intra_day_bars
  map.resources :daily_bars
  map.resources :scans
  map.resources :strategies
  map.resources :derived_value_types
  map.resources :positions
  map.resources :contract_types
  map.resources :portfolios
  map.resources :plot_types
  map.resources :plot_attributes
  map.resources :listing_categories
  map.resources :daily_returns
  map.resources :aggregations
  map.resources :tickers, :has_one => :current_listing, :collection => { :find => :get }, :has_many => [ :tda_positions ]
  map.resources :historical_attributes
  map.resources :stat_values
  map.resources :current_listing, :contoller => 'current_listing'
  map.resources :exchanges
  map.resources :daily_closes, :member => { :plot => :get },:collection => { :reload => :get, :begin_load => :post, :progress => :get }
  map.resources :watch_lists, :has_one => :tda_position,
                              :member => { :plot => :get, :open => :get, :close => :get, :retire => :get },
                              :collection => { :entries => :get, :exits => :get }

  map.root :controller => 'tickers', :action => 'index'

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
