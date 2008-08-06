require 'test_helper'

class TickersControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_template 'index'
  end
  
  def test_show
    get :show, :id => Ticker.first
    assert_template 'show'
  end
  
  def test_new
    get :new
    assert_template 'new'
  end
  
  def test_create_invalid
    Ticker.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end
  
  def test_create_valid
    Ticker.any_instance.stubs(:valid?).returns(true)
    post :create
    assert_redirected_to ticker_url(assigns(:ticker))
  end
  
  def test_edit
    get :edit, :id => Ticker.first
    assert_template 'edit'
  end
  
  def test_update_invalid
    Ticker.any_instance.stubs(:valid?).returns(false)
    put :update, :id => Ticker.first
    assert_template 'edit'
  end
  
  def test_update_valid
    Ticker.any_instance.stubs(:valid?).returns(true)
    put :update, :id => Ticker.first
    assert_redirected_to ticker_url(assigns(:ticker))
  end
  
  def test_destroy
    ticker = Ticker.first
    delete :destroy, :id => ticker
    assert_redirected_to tickers_url
    assert !Ticker.exists?(ticker.id)
  end
end
