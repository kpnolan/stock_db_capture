require File.dirname(__FILE__) + '/../test_helper'
require 'tda_positions_controller'

# Re-raise errors caught by the controller.
class TdaPositionsController; def rescue_action(e) raise e end; end

class TdaPositionsControllerTest < Test::Unit::TestCase
  fixtures :tda_positions

  def setup
    @controller = TdaPositionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:tda_positions)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_tda_position
    old_count = TdaPosition.count
    post :create, :tda_position => { }
    assert_equal old_count + 1, TdaPosition.count

    assert_redirected_to tda_position_path(assigns(:tda_position))
  end

  def test_should_show_tda_position
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_tda_position
    put :update, :id => 1, :tda_position => { }
    assert_redirected_to tda_position_path(assigns(:tda_position))
  end

  def test_should_destroy_tda_position
    old_count = TdaPosition.count
    delete :destroy, :id => 1
    assert_equal old_count-1, TdaPosition.count

    assert_redirected_to tda_positions_path
  end
end
