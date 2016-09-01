require "./test_helper"
require "../raml/api"

class RequestBodyTest < Minitest::Test

  def setup
    @api = load_parser("request_body").api as RAML::Api
  end

  def api : RAML::Api
    @api as RAML::Api
  end

  def request(url)
    api.all_resources[url].requests.first
  end

  def test_type_decl
    serializations = request("/users").body.serializations
    assert_equal 1, serializations.size
    assert_equal "User", serializations.first.data_type.name
    assert_equal "application/json", serializations.first.format
  end
  
  def test_media_type
    serializations = request("/groups").body.serializations
    assert_equal 2, serializations.size
    assert_equal "application/json", serializations.first.format
   # assert_equal "text/xml", types.last[1].as(RAML::MediaType).media_type
  end

end