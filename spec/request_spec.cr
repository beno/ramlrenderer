require "./test_helper"
require "../raml/api"

class RequestTest < Minitest::Test
  
  def setup
    @api = load_parser.api as RAML::Api
  end

  def api : RAML::Api
    @api as RAML::Api
  end
  
  def resource(url)
    api.all_resources[url]
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
    assert request.query_parameters.has_key? "query"
  end
  
  def test_interpolate_resourcePathName
    resource = resource("/articles")
    request = resource.requests.first
    assert_equal "Get a list of articles.", request.spec("description")
  end
  
  def test_request_uri_parameters
    resource = resource("/books/{bookId}")
    request = resource.requests.first
    assert request.uri_parameters.has_key? "bookId"
    assert request.uri_parameters["bookId"].as(Hash).has_key? "type"
    assert_equal "string", request.uri_parameters["bookId"].as(Hash)["type"]
  end
  
  def test_request_uri_parameters_spec
    resource = resource("/authors/{authorId}")
    request = resource.requests.first
    assert request.uri_parameters.has_key? "authorId"
    assert request.uri_parameters["authorId"].as(Hash).has_key? "type"
    assert_equal "integer", request.uri_parameters["authorId"].as(Hash)["type"]
  end



end
