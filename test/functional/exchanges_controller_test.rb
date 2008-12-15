require File.dirname(__FILE__) + '/../test_helper'
require 'exchanges_controller'

# Re-raise errors caught by the controller.
class ExchangesController; def rescue_action(e) raise e end; end

class ExchangesControllerTest < Test::Unit::TestCase
  fixtures :exchanges

  def setup
    @controller = ExchangesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:exchanges)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_exchange
    old_count = Exchange.count
    post :create, :exchange => { }
    assert_equal old_count + 1, Exchange.count

    assert_redirected_to exchange_path(assigns(:exchange))
  end

  def test_should_show_exchange
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_exchange
    put :update, :id => 1, :exchange => { }
    assert_redirected_to exchange_path(assigns(:exchange))
  end

  def test_should_destroy_exchange
    old_count = Exchange.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Exchange.count

    assert_redirected_to exchanges_path
  end
end
