class CurrentListingController <  ApplicationController
  make_resourceful do
    belongs_to :ticker
    actions :index, :edit, :show
  end
end
