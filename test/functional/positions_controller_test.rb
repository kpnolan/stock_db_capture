require File.dirname(__FILE__) + '/../test_helper'
require 'positions_controller'

# Re-raise errors caught by the controller.
class PositionsController; def rescue_action(e) raise e end; end

class PositionsControllerTest < Test::Unit::TestCase
  fixtures :positions

  def setup
    @controller = PositionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:positions)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_position
    old_count = Position.count
    post :create, :position => { }
    assert_equal old_count + 1, Position.count

    assert_redirected_to position_path(assigns(:position))
  end

  def test_should_show_position
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_position
    put :update, :id => 1, :position => { }
    assert_redirected_to position_path(assigns(:position))
  end

  def test_should_destroy_position
    old_count = Position.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Position.count

    assert_redirected_to positions_path
  end
end
