require "./test_helper"
require "../raml/parser"
require "../raml/api"

class NestedTest < Minitest::Test

  def setup
    @api = load_parser("deep_nested").api as RAML::Api
  end

  def api : RAML::Api
    @api as RAML::Api
  end
  
  def test_all_resources
    assert_equal 3, api.all_resources.size
  end

end
