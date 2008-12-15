require File.dirname(__FILE__) + '/../test_helper'
require 'stat_values_controller'

# Re-raise errors caught by the controller.
class StatValuesController; def rescue_action(e) raise e end; end

class StatValuesControllerTest < Test::Unit::TestCase
  fixtures :stat_values

  def setup
    @controller = StatValuesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:stat_values)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_stat_value
    old_count = StatValue.count
    post :create, :stat_value => { }
    assert_equal old_count + 1, StatValue.count

    assert_redirected_to stat_value_path(assigns(:stat_value))
  end

  def test_should_show_stat_value
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_stat_value
    put :update, :id => 1, :stat_value => { }
    assert_redirected_to stat_value_path(assigns(:stat_value))
  end

  def test_should_destroy_stat_value
    old_count = StatValue.count
    delete :destroy, :id => 1
    assert_equal old_count-1, StatValue.count

    assert_redirected_to stat_values_path
  end
end
