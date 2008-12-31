require File.dirname(__FILE__) + '/../test_helper'
require 'plot_types_controller'

# Re-raise errors caught by the controller.
class PlotTypesController; def rescue_action(e) raise e end; end

class PlotTypesControllerTest < Test::Unit::TestCase
  fixtures :plot_types

  def setup
    @controller = PlotTypesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:plot_types)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_plot_type
    old_count = PlotType.count
    post :create, :plot_type => { }
    assert_equal old_count + 1, PlotType.count

    assert_redirected_to plot_type_path(assigns(:plot_type))
  end

  def test_should_show_plot_type
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_plot_type
    put :update, :id => 1, :plot_type => { }
    assert_redirected_to plot_type_path(assigns(:plot_type))
  end

  def test_should_destroy_plot_type
    old_count = PlotType.count
    delete :destroy, :id => 1
    assert_equal old_count-1, PlotType.count

    assert_redirected_to plot_types_path
  end
end
