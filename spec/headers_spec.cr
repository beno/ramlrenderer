require "./test_helper"
require "../raml/api"

class HeadersTest < Minitest::Test

  def setup
    @api = load_parser("headers").api as RAML::Api
  end

  def api : RAML::Api
    @api as RAML::Api
  end

  def request(url)
    api.all_resources[url].requests.first
  end

  def test_header_size
    assert_equal 2, request("/users").spec("headers").as(Hash).size
  end
  
  def test_header_traits
    request("/users").spec("headers").as(Hash).each do |name, spec|
      assert spec.as(Hash).has_key? "description"
    end
  end


end