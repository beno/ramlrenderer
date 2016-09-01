require "./test_helper"
require "../raml/parser"
require "../raml/api"

class ResponseTest < Minitest::Test

  def setup
    @api = load_parser.api as RAML::Api
  end
  
  def api : RAML::Api
    @api as RAML::Api
  end
  
  def responses(url)
    api.all_resources[url].requests.first.responses
  end
  
      
  def xtest_response_data_type_string
    response = responses("/things").first
    serialization = response.body.serializations.first
    assert serialization.data_type.properties.has_key? "title"
    refute serialization.data_type.properties.has_key? "foo"
  end
  
  def xtest_response_data_type_hash
    response = responses("/things").last
    serialization = response.body.serializations.first
    assert serialization.data_type
    assert serialization.data_type.properties.has_key? "title"
    assert serialization.data_type.properties.has_key? "foo"
  end
  
  
  def test_interpolate_resourcePath_type
    response = responses("/articles").first
    assert_equal 1, response.body.serializations.size
    response.body.serializations.each do |serialization|
      data_type = serialization.data_type
      assert_equal "Article", data_type.name
      assert data_type.properties.has_key? "title"
    end
  end
  

    
end