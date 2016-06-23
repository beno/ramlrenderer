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
  
  def resource(url)
    api.all_resources[url]
  end
  
  def test_version
    assert_equal "v1", (@api as RAML::Api).spec("version")
  end
  
  def test_base_uri
    assert_equal "https://api.example.com/v1", (@api as RAML::Api).spec("baseUri")
  end
    
  def test_resource_type_merge
    spec = api.resources["/things"] as Hash
    assert spec.has_key? "endpoint"
  end

  def test_resource_type_merge_2
    spec = api.resources["/others"] as Hash
    assert spec.has_key? "endpoint"
  end
  
  def test_resource_traits_merge
    resource = resource("/things")
    resource.requests.each do |request|
      assert (request.spec("queryParameters") as Hash).has_key? "access_token"
    end
  end
  
  def test_request_traits_merge
    resource = resource("/things")
    request = resource.requests.first
    assert (request.spec("queryParameters") as Hash).has_key? "query"
  end
  
  def test_response_data_type_string
    resource = resource("/things")
    request = resource.requests.first
    response = request.responses.first
    media_type = response.media_types[response.media_types.keys.first]
    assert media_type.data_type
    assert media_type.data_type.properties.has_key? "title"
    refute media_type.data_type.properties.has_key? "foo"
  end
  
  def test_response_data_type_hash
    resource = resource("/things")
    request = resource.requests.first
    response = request.responses.last
    media_type = response.media_types[response.media_types.keys.first]
    assert media_type.data_type
    assert media_type.data_type.properties.has_key? "title"
    assert media_type.data_type.properties.has_key? "foo"
  end
  
  def test_resource_type_variable
    #resource = resource("/others")
    #request = resource.requests.first
    #assert (request.spec("queryParameters") as Hash).has_key? "query"
  end


end