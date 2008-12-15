require File.dirname(__FILE__) + '/../test_helper'
require 'real_time_quotes_controller'

# Re-raise errors caught by the controller.
class RealTimeQuotesController; def rescue_action(e) raise e end; end

class RealTimeQuotesControllerTest < Test::Unit::TestCase
  fixtures :real_time_quotes

  def setup
    @controller = RealTimeQuotesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:real_time_quotes)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_real_time_quote
    old_count = RealTimeQuote.count
    post :create, :real_time_quote => { }
    assert_equal old_count + 1, RealTimeQuote.count

    assert_redirected_to real_time_quote_path(assigns(:real_time_quote))
  end

  def test_should_show_real_time_quote
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_real_time_quote
    put :update, :id => 1, :real_time_quote => { }
    assert_redirected_to real_time_quote_path(assigns(:real_time_quote))
  end

  def test_should_destroy_real_time_quote
    old_count = RealTimeQuote.count
    delete :destroy, :id => 1
    assert_equal old_count-1, RealTimeQuote.count

    assert_redirected_to real_time_quotes_path
  end
end
