require "./test_helper"
require "../raml/api"

class QueryStringTest < Minitest::Test

  def setup
    @api = load_parser("query_string").api as RAML::Api
  end

  def api : RAML::Api
    @api as RAML::Api
  end

  def request(url)
    api.all_resources[url].requests.first
  end

  def test_qs_size
    assert_equal 4, request("/locations").query_string.as(RAML::QueryString).properties(0).size
    assert_equal 3, request("/locations").query_string.as(RAML::QueryString).properties(1).size
  end

end