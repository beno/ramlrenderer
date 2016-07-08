require "./test_helper"
require "../raml/parser"
require "../raml/api"

class ResourceTest < Minitest::Test

  def setup
    @api = load_parser.api as RAML::Api
  end
  
  def api : RAML::Api
    @api as RAML::Api
  end
  
  def resource(url)
    api.all_resources[url]
  end
  
    
  def test_resource_type_merge
    spec = api.resources["/things"] as Hash
    assert spec.has_key? "endpoint"
  end

  def test_resource_type_merge_2
    spec = api.resources["/articles"] as Hash
    assert spec.has_key? "endpoint"
  end
  
  def test_interpolate_resourcePath
    resource = resource("/articles")
    assert_equal "Collection of available ARTICLES.", resource.spec("description")
  end
    
end