require 'test_helper'

class ExchangesControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_template 'index'
  end
  
  def test_show
    get :show, :id => Exchange.first
    assert_template 'show'
  end
  
  def test_new
    get :new
    assert_template 'new'
  end
  
  def test_create_invalid
    Exchange.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end
  
  def test_create_valid
    Exchange.any_instance.stubs(:valid?).returns(true)
    post :create
    assert_redirected_to exchange_url(assigns(:exchange))
  end
  
  def test_edit
    get :edit, :id => Exchange.first
    assert_template 'edit'
  end
  
  def test_update_invalid
    Exchange.any_instance.stubs(:valid?).returns(false)
    put :update, :id => Exchange.first
    assert_template 'edit'
  end
  
  def test_update_valid
    Exchange.any_instance.stubs(:valid?).returns(true)
    put :update, :id => Exchange.first
    assert_redirected_to exchange_url(assigns(:exchange))
  end
  
  def test_destroy
    exchange = Exchange.first
    delete :destroy, :id => exchange
    assert_redirected_to exchanges_url
    assert !Exchange.exists?(exchange.id)
  end
end
