require File.dirname(__FILE__) + '/../test_helper'
require 'position_series_controller'

# Re-raise errors caught by the controller.
class PositionSeriesController; def rescue_action(e) raise e end; end

class PositionSeriesControllerTest < Test::Unit::TestCase
  fixtures :position_series

  def setup
    @controller = PositionSeriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:position_series)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_position_series
    old_count = PositionSeries.count
    post :create, :position_series => { }
    assert_equal old_count + 1, PositionSeries.count

    assert_redirected_to position_series_path(assigns(:position_series))
  end

  def test_should_show_position_series
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_position_series
    put :update, :id => 1, :position_series => { }
    assert_redirected_to position_series_path(assigns(:position_series))
  end

  def test_should_destroy_position_series
    old_count = PositionSeries.count
    delete :destroy, :id => 1
    assert_equal old_count-1, PositionSeries.count

    assert_redirected_to position_series_path
  end
end
