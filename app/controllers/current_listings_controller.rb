class CurrentListingsController < ApplicationController
  make_resourceful do
    actions :index, :edit, :show
  end
end
