class OrdersController < ApplicationController
  make_resourceful do
    actions :all
  end
end
