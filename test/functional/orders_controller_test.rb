require File.dirname(__FILE__) + '/../test_helper'
require 'orders_controller'

# Re-raise errors caught by the controller.
class OrdersController; def rescue_action(e) raise e end; end

class OrdersControllerTest < Test::Unit::TestCase
  fixtures :orders

  def setup
    @controller = OrdersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:orders)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_order
    old_count = Order.count
    post :create, :order => { }
    assert_equal old_count + 1, Order.count

    assert_redirected_to order_path(assigns(:order))
  end

  def test_should_show_order
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_order
    put :update, :id => 1, :order => { }
    assert_redirected_to order_path(assigns(:order))
  end

  def test_should_destroy_order
    old_count = Order.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Order.count

    assert_redirected_to orders_path
  end
end
