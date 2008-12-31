class PlotAttributesController < ApplicationController
  make_resourceful do
    belongs_to :ticker
    actions :all
  end
end
