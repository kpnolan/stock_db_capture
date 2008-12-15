require File.dirname(__FILE__) + '/../test_helper'
require 'tickers_controller'

# Re-raise errors caught by the controller.
class TickersController; def rescue_action(e) raise e end; end

class TickersControllerTest < Test::Unit::TestCase
  fixtures :tickers

  def setup
    @controller = TickersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:tickers)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_ticker
    old_count = Ticker.count
    post :create, :ticker => { }
    assert_equal old_count + 1, Ticker.count

    assert_redirected_to ticker_path(assigns(:ticker))
  end

  def test_should_show_ticker
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_ticker
    put :update, :id => 1, :ticker => { }
    assert_redirected_to ticker_path(assigns(:ticker))
  end

  def test_should_destroy_ticker
    old_count = Ticker.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Ticker.count

    assert_redirected_to tickers_path
  end
end
