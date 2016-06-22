require "./test_helper"
require "../raml/parser"
require "../raml/api"

class ApiTest < Minitest::Test

  def setup
    @api = load_parser.api as RAML::Api
  end
  
  def test_version
    assert_equal "v1", (@api as RAML::Api).spec["version"]
  end
  
  def test_base_uri
    assert_equal "https://api.example.com/v1", (@api as RAML::Api).base_uri
  end

end