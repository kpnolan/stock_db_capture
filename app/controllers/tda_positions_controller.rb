class TdaPositionsController < ApplicationController
  make_resourceful do
    belongs_to :watch_list
    actions :all

    before :new do
      debugger
    end
  end

  def singular?
    true
  end
end
