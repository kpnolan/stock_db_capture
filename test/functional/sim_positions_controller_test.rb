require File.dirname(__FILE__) + '/../test_helper'
require 'sim_positions_controller'

# Re-raise errors caught by the controller.
class SimPositionsController; def rescue_action(e) raise e end; end

class SimPositionsControllerTest < Test::Unit::TestCase
  fixtures :sim_positions

  def setup
    @controller = SimPositionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:sim_positions)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_sim_position
    old_count = SimPosition.count
    post :create, :sim_position => { }
    assert_equal old_count + 1, SimPosition.count

    assert_redirected_to sim_position_path(assigns(:sim_position))
  end

  def test_should_show_sim_position
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_sim_position
    put :update, :id => 1, :sim_position => { }
    assert_redirected_to sim_position_path(assigns(:sim_position))
  end

  def test_should_destroy_sim_position
    old_count = SimPosition.count
    delete :destroy, :id => 1
    assert_equal old_count-1, SimPosition.count

    assert_redirected_to sim_positions_path
  end
end
