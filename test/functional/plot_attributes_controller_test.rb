require File.dirname(__FILE__) + '/../test_helper'
require 'plot_attributes_controller'

# Re-raise errors caught by the controller.
class PlotAttributesController; def rescue_action(e) raise e end; end

class PlotAttributesControllerTest < Test::Unit::TestCase
  fixtures :plot_attributes

  def setup
    @controller = PlotAttributesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:plot_attributes)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_plot_attributes
    old_count = PlotAttributes.count
    post :create, :plot_attributes => { }
    assert_equal old_count + 1, PlotAttributes.count

    assert_redirected_to plot_attributes_path(assigns(:plot_attributes))
  end

  def test_should_show_plot_attributes
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_plot_attributes
    put :update, :id => 1, :plot_attributes => { }
    assert_redirected_to plot_attributes_path(assigns(:plot_attributes))
  end

  def test_should_destroy_plot_attributes
    old_count = PlotAttributes.count
    delete :destroy, :id => 1
    assert_equal old_count-1, PlotAttributes.count

    assert_redirected_to plot_attributes_path
  end
end
