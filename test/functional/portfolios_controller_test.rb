require File.dirname(__FILE__) + '/../test_helper'
require 'portfolios_controller'

# Re-raise errors caught by the controller.
class PortfoliosController; def rescue_action(e) raise e end; end

class PortfoliosControllerTest < Test::Unit::TestCase
  fixtures :portfolios

  def setup
    @controller = PortfoliosController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:portfolios)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_portfolio
    old_count = Portfolio.count
    post :create, :portfolio => { }
    assert_equal old_count + 1, Portfolio.count

    assert_redirected_to portfolio_path(assigns(:portfolio))
  end

  def test_should_show_portfolio
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_portfolio
    put :update, :id => 1, :portfolio => { }
    assert_redirected_to portfolio_path(assigns(:portfolio))
  end

  def test_should_destroy_portfolio
    old_count = Portfolio.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Portfolio.count

    assert_redirected_to portfolios_path
  end
end
