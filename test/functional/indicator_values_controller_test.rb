require File.dirname(__FILE__) + '/../test_helper'
require 'indicator_values_controller'

# Re-raise errors caught by the controller.
class IndicatorValuesController; def rescue_action(e) raise e end; end

class IndicatorValuesControllerTest < Test::Unit::TestCase
  fixtures :indicator_values

  def setup
    @controller = IndicatorValuesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:indicator_values)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_indicator_value
    old_count = IndicatorValue.count
    post :create, :indicator_value => { }
    assert_equal old_count + 1, IndicatorValue.count

    assert_redirected_to indicator_value_path(assigns(:indicator_value))
  end

  def test_should_show_indicator_value
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_indicator_value
    put :update, :id => 1, :indicator_value => { }
    assert_redirected_to indicator_value_path(assigns(:indicator_value))
  end

  def test_should_destroy_indicator_value
    old_count = IndicatorValue.count
    delete :destroy, :id => 1
    assert_equal old_count-1, IndicatorValue.count

    assert_redirected_to indicator_values_path
  end
end
