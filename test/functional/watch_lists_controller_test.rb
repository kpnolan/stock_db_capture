require File.dirname(__FILE__) + '/../test_helper'
require 'watch_lists_controller'

# Re-raise errors caught by the controller.
class WatchListsController; def rescue_action(e) raise e end; end

class WatchListsControllerTest < Test::Unit::TestCase
  fixtures :watch_lists

  def setup
    @controller = WatchListsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:watch_lists)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_watch_list
    old_count = WatchList.count
    post :create, :watch_list => { }
    assert_equal old_count + 1, WatchList.count

    assert_redirected_to watch_list_path(assigns(:watch_list))
  end

  def test_should_show_watch_list
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_watch_list
    put :update, :id => 1, :watch_list => { }
    assert_redirected_to watch_list_path(assigns(:watch_list))
  end

  def test_should_destroy_watch_list
    old_count = WatchList.count
    delete :destroy, :id => 1
    assert_equal old_count-1, WatchList.count

    assert_redirected_to watch_lists_path
  end
end
