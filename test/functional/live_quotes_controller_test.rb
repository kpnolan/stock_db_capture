require File.dirname(__FILE__) + '/../test_helper'
require 'live_quotes_controller'

# Re-raise errors caught by the controller.
class LiveQuotesController; def rescue_action(e) raise e end; end

class LiveQuotesControllerTest < Test::Unit::TestCase
  fixtures :live_quotes

  def setup
    @controller = LiveQuotesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:live_quotes)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_live_quote
    old_count = LiveQuote.count
    post :create, :live_quote => { }
    assert_equal old_count + 1, LiveQuote.count

    assert_redirected_to live_quote_path(assigns(:live_quote))
  end

  def test_should_show_live_quote
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_live_quote
    put :update, :id => 1, :live_quote => { }
    assert_redirected_to live_quote_path(assigns(:live_quote))
  end

  def test_should_destroy_live_quote
    old_count = LiveQuote.count
    delete :destroy, :id => 1
    assert_equal old_count-1, LiveQuote.count

    assert_redirected_to live_quotes_path
  end
end
