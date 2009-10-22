require File.dirname(__FILE__) + '/../test_helper'
require 'splits_controller'

# Re-raise errors caught by the controller.
class SplitsController; def rescue_action(e) raise e end; end

class SplitsControllerTest < Test::Unit::TestCase
  fixtures :splits

  def setup
    @controller = SplitsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:splits)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_splits
    old_count = Splits.count
    post :create, :splits => { }
    assert_equal old_count + 1, Splits.count

    assert_redirected_to splits_path(assigns(:splits))
  end

  def test_should_show_splits
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_splits
    put :update, :id => 1, :splits => { }
    assert_redirected_to splits_path(assigns(:splits))
  end

  def test_should_destroy_splits
    old_count = Splits.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Splits.count

    assert_redirected_to splits_path
  end
end
