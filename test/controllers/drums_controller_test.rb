require 'test_helper'

class DrumsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @drum = drums(:one)
  end

  test "should get index" do
    get drums_url, as: :json
    assert_response :success
  end

  test "should create drum" do
    assert_difference('Drum.count') do
      post drums_url, params: { drum: { name: @drum.name } }, as: :json
    end

    assert_response 201
  end

  test "should show drum" do
    get drum_url(@drum), as: :json
    assert_response :success
  end

  test "should update drum" do
    patch drum_url(@drum), params: { drum: { name: @drum.name } }, as: :json
    assert_response 200
  end

  test "should destroy drum" do
    assert_difference('Drum.count', -1) do
      delete drum_url(@drum), as: :json
    end

    assert_response 204
  end
end
