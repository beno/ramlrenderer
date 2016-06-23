require "./test_helper"
require "../raml/parser"
require "../raml/api"

class ApiTest < Minitest::Test

  def setup
    @api = load_parser.api as RAML::Api
  end
  
  def api : RAML::Api
    @api as RAML::Api
  end
  
  def test_version
    assert_equal "v1", (@api as RAML::Api).spec("version")
  end
  
  def test_base_uri
    assert_equal "https://api.example.com/v1", (@api as RAML::Api).spec("baseUri")
  end
    
  def test_resource_type_merge
    spec = api.resources[api.resources.first_key] as Hash
    assert spec.has_key? "endpoint"
  end
  
  def test_resource_traits_merge
    resource = (api.resources[api.resources.first_key] as Hash)["endpoint"] as RAML::Resource
    resource.requests.each do |request|
      assert (request.spec("queryParameters") as Hash).has_key? "access_token"
    end
  end
  
  def test_request_traits_merge
    resource = (api.resources[api.resources.first_key] as Hash)["endpoint"] as RAML::Resource
    request = resource.requests.first
    assert (request.spec("queryParameters") as Hash).has_key? "query"
  end
  
  def test_response_data_type
    resource = (api.resources[api.resources.first_key] as Hash)["endpoint"] as RAML::Resource
    request = resource.requests.first
    response = request.responses.first
  end
  

end