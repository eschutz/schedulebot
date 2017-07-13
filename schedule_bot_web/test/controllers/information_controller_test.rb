require 'test_helper'

class InformationControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get information_index_url
    assert_response :success
  end

end
