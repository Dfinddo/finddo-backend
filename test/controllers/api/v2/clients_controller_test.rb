require 'test_helper'

class Api::V2::ClientsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get api_v2_clients_create_url
    assert_response :success
  end

  test "should get show" do
    get api_v2_clients_show_url
    assert_response :success
  end

end
