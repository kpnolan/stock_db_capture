require File.dirname(__FILE__) + '/../test_helper'
require 'intra_day_bars_controller'

# Re-raise errors caught by the controller.
class IntraDayBarsController; def rescue_action(e) raise e end; end

class IntraDayBarsControllerTest < Test::Unit::TestCase
  fixtures :intra_day_bars

  def setup
    @controller = IntraDayBarsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:intra_day_bars)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_intra_day_bar
    old_count = IntraDayBar.count
    post :create, :intra_day_bar => { }
    assert_equal old_count + 1, IntraDayBar.count

    assert_redirected_to intra_day_bar_path(assigns(:intra_day_bar))
  end

  def test_should_show_intra_day_bar
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_intra_day_bar
    put :update, :id => 1, :intra_day_bar => { }
    assert_redirected_to intra_day_bar_path(assigns(:intra_day_bar))
  end

  def test_should_destroy_intra_day_bar
    old_count = IntraDayBar.count
    delete :destroy, :id => 1
    assert_equal old_count-1, IntraDayBar.count

    assert_redirected_to intra_day_bars_path
  end
end
