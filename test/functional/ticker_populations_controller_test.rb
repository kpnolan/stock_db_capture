require File.dirname(__FILE__) + '/../test_helper'
require 'ticker_populations_controller'

# Re-raise errors caught by the controller.
class TickerPopulationsController; def rescue_action(e) raise e end; end

class TickerPopulationsControllerTest < Test::Unit::TestCase
  fixtures :ticker_populations

  def setup
    @controller = TickerPopulationsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:ticker_populations)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_ticker_population
    old_count = TickerPopulation.count
    post :create, :ticker_population => { }
    assert_equal old_count + 1, TickerPopulation.count

    assert_redirected_to ticker_population_path(assigns(:ticker_population))
  end

  def test_should_show_ticker_population
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_ticker_population
    put :update, :id => 1, :ticker_population => { }
    assert_redirected_to ticker_population_path(assigns(:ticker_population))
  end

  def test_should_destroy_ticker_population
    old_count = TickerPopulation.count
    delete :destroy, :id => 1
    assert_equal old_count-1, TickerPopulation.count

    assert_redirected_to ticker_populations_path
  end
end
